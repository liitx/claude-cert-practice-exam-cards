#!/usr/bin/env node
const fs = require('fs');
const { execSync } = require('child_process');

const ISSUE_NUMBER = process.env.ISSUE_NUMBER;
const ISSUE_BODY = process.env.ISSUE_BODY || '';
const ISSUE_USER = process.env.ISSUE_USER || 'unknown';

const LIMITS = {
  title: 200,
  text: 4000,
  cardsPerSubmit: 100,
  totalBytes: 200_000,
  subjectsPerSubmit: 30,
};

function sh(cmd) {
  return execSync(cmd, { stdio: ['ignore', 'pipe', 'pipe'] }).toString().trim();
}

function ghComment(body) {
  fs.writeFileSync('/tmp/comment.md', body);
  execSync(`gh issue comment ${ISSUE_NUMBER} -F /tmp/comment.md`, { stdio: 'inherit' });
}

function fail(reason) {
  const body = [
    '### Submission rejected',
    '',
    reason,
    '',
    'Fix the JSON in the issue body and remove + re-apply the `submission` label to retry, or open a new issue. The "share to library" button in the app generates a properly-formatted payload.',
  ].join('\n');
  ghComment(body);
  process.exit(0);
}

function ok(summary) {
  const body = [
    '### Merged into the library',
    '',
    summary,
    '',
    'The site will reflect this change after the next GitHub Pages rebuild (typically 1-2 minutes). Your own progress and any private decks you keep in localStorage are unaffected.',
  ].join('\n');
  ghComment(body);
  execSync(`gh issue close ${ISSUE_NUMBER}`, { stdio: 'inherit' });
}

const fenceMatch = ISSUE_BODY.match(/```json\s*([\s\S]*?)```/);
if (!fenceMatch) fail('No ```json fenced code block found in the issue body.');

const jsonText = fenceMatch[1];
if (jsonText.length > LIMITS.totalBytes) fail(`Submission too large (${jsonText.length} bytes, max ${LIMITS.totalBytes}).`);

let payload;
try { payload = JSON.parse(jsonText); }
catch (e) { fail('JSON failed to parse: ' + e.message); }

function htmlEscape(s) {
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function checkString(s, max, name) {
  if (typeof s !== 'string') return `${name} must be a string`;
  const t = s.trim();
  if (!t) return `${name} cannot be empty`;
  if (s.length > max) return `${name} too long (max ${max})`;
  return null;
}

function checkColor(c) {
  if (typeof c !== 'string' || !/^#[0-9a-fA-F]{6}$/.test(c)) return 'color must be #rrggbb';
  return null;
}

function checkSubjectKey(k) {
  if (typeof k !== 'string' || !/^[A-Za-z0-9]{1,8}$/.test(k)) return `subject key "${k}" must be 1-8 letters/digits`;
  return null;
}

const ALLOWED_TYPES = new Set(['basic', 'mc', 'ms', 'tf', 'fib']);
const MAX_CHOICES = 8;
const MAX_ACCEPTED = 10;
const MAX_IMAGE_LEN = 1_200_000; // base64 of an 800KB image is ~1.1MB

function sanitizeCard(c) {
  for (const f of ['scn', 'topic', 'q']) {
    const err = checkString(c[f], LIMITS.text, f);
    if (err) return err;
    c[f] = htmlEscape(c[f].trim());
  }
  const t = c.type || 'basic';
  if (!ALLOWED_TYPES.has(t)) return `type "${t}" not allowed`;
  c.type = t;
  if (t === 'basic') {
    const err = checkString(c.a, LIMITS.text, 'a');
    if (err) return err;
    c.a = htmlEscape(c.a.trim());
  } else {
    if (c.a !== undefined && c.a !== null && c.a !== '') {
      const err = checkString(c.a, LIMITS.text, 'a');
      if (err) return err;
      c.a = htmlEscape(c.a.trim());
    } else {
      delete c.a;
    }
  }
  if (t === 'mc' || t === 'ms') {
    if (!Array.isArray(c.choices) || c.choices.length < 2 || c.choices.length > MAX_CHOICES) return 'choices must be 2-' + MAX_CHOICES;
    const cleaned = [];
    for (const ch of c.choices) {
      const err = checkString(ch, LIMITS.text, 'choice');
      if (err) return err;
      cleaned.push(htmlEscape(ch.trim()));
    }
    c.choices = cleaned;
    if (t === 'mc') {
      if (!Number.isInteger(c.correct) || c.correct < 0 || c.correct >= cleaned.length) return 'mc correct must be a valid choice index';
    } else {
      if (!Array.isArray(c.correct) || c.correct.length === 0) return 'ms correct must be a non-empty array';
      for (const i of c.correct) {
        if (!Number.isInteger(i) || i < 0 || i >= cleaned.length) return 'ms correct contains invalid index';
      }
      c.correct = [...new Set(c.correct)].sort((a, b) => a - b);
    }
  } else if (t === 'tf') {
    if (c.correct !== true && c.correct !== false) return 'tf correct must be true or false';
  } else if (t === 'fib') {
    if (!Array.isArray(c.accepted) || c.accepted.length === 0 || c.accepted.length > MAX_ACCEPTED) return 'accepted must be 1-' + MAX_ACCEPTED + ' strings';
    const cleaned = [];
    for (const ans of c.accepted) {
      const err = checkString(ans, LIMITS.text, 'accepted');
      if (err) return err;
      cleaned.push(htmlEscape(ans.trim()));
    }
    c.accepted = cleaned;
  }
  if (c.why !== undefined && c.why !== null && c.why !== '') {
    const err = checkString(c.why, LIMITS.text, 'why');
    if (err) return err;
    c.why = htmlEscape(c.why.trim());
  } else {
    c.why = '';
  }
  if ('miss' in c && typeof c.miss !== 'boolean') return 'miss must be boolean';
  c.miss = !!c.miss;
  if (c.pick !== undefined && c.pick !== null && c.pick !== '') {
    if (typeof c.pick !== 'string' || c.pick.length > 100) return 'pick must be a string up to 100 chars';
    c.pick = htmlEscape(c.pick.trim());
  } else {
    delete c.pick;
  }
  if (c.image !== undefined && c.image !== null && c.image !== '') {
    if (typeof c.image !== 'string' || !/^data:image\/(png|jpe?g|gif|webp);base64,/.test(c.image)) return 'image must be a base64 data URL';
    if (c.image.length > MAX_IMAGE_LEN) return 'image too large';
  } else {
    delete c.image;
  }
  return null;
}

function slug(s) {
  return String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 40) || 'deck';
}

function serializeCard(c) {
  const t = c.type || 'basic';
  const out = { id: c.id, scn: c.scn, topic: c.topic, q: c.q, why: c.why, miss: c.miss };
  if (t !== 'basic') out.type = t;
  if (c.a) out.a = c.a;
  if (t === 'mc' || t === 'ms') { out.choices = c.choices; out.correct = c.correct; }
  if (t === 'tf') out.correct = c.correct;
  if (t === 'fib') out.accepted = c.accepted;
  if (c.image) out.image = c.image;
  if (c.pick) out.pick = c.pick;
  return out;
}

const decksPath = 'decks.json';
const raw = fs.readFileSync(decksPath, 'utf8');
const data = JSON.parse(raw);
if (!Array.isArray(data.decks)) fail('decks.json is malformed (no decks array).');

let summary = '';
let summaryShort = '';

if (payload.type === 'new-deck') {
  const d = payload.deck;
  if (!d || typeof d !== 'object') fail('new-deck submission missing "deck" object.');
  const nameErr = checkString(d.name, LIMITS.title, 'deck.name');
  if (nameErr) fail(nameErr);
  if (!d.scenarios || typeof d.scenarios !== 'object') fail('deck.scenarios missing.');
  if (!Array.isArray(d.cards)) fail('deck.cards must be an array.');
  if (d.cards.length === 0) fail('deck has no cards.');
  if (d.cards.length > LIMITS.cardsPerSubmit) fail(`Too many cards (max ${LIMITS.cardsPerSubmit}).`);
  if (Object.keys(d.scenarios).length > LIMITS.subjectsPerSubmit) fail(`Too many subjects (max ${LIMITS.subjectsPerSubmit}).`);

  const cleanScenarios = {};
  for (const [k, v] of Object.entries(d.scenarios)) {
    const ke = checkSubjectKey(k); if (ke) fail(ke);
    if (!v || typeof v !== 'object') fail(`subject "${k}" malformed.`);
    const le = checkString(v.label, LIMITS.title, `subject "${k}" label`); if (le) fail(le);
    const ce = checkColor(v.color); if (ce) fail(`subject "${k}": ${ce}`);
    cleanScenarios[k] = { label: htmlEscape(v.label.trim()), color: v.color.toLowerCase() };
  }

  for (const c of d.cards) {
    if (!c.scn || !(c.scn in cleanScenarios)) fail(`card uses unknown subject "${c.scn}".`);
    const err = sanitizeCard(c);
    if (err) fail(`card ${c.id || '(no id)'}: ${err}`);
  }

  let baseId = slug(d.name);
  let id = baseId;
  let n = 2;
  while (data.decks.some(x => x.id === id)) id = baseId + '-' + (n++);

  const usedCardIds = new Set();
  d.cards.forEach((c, i) => {
    let cid = (typeof c.id === 'string' && /^[A-Za-z0-9-_]{1,60}$/.test(c.id)) ? c.id : `${id}-c${i + 1}`;
    while (usedCardIds.has(cid)) cid = `${id}-c${i + 1}-${Math.random().toString(36).slice(2, 5)}`;
    c.id = cid;
    usedCardIds.add(cid);
  });

  data.decks.push({
    id,
    name: htmlEscape(d.name.trim()),
    scenarios: cleanScenarios,
    cards: d.cards.map(serializeCard),
  });

  summary = `New deck **${data.decks[data.decks.length - 1].name}** added (id \`${id}\`, ${d.cards.length} cards, ${Object.keys(cleanScenarios).length} subjects).`;
  summaryShort = `Add deck "${data.decks[data.decks.length - 1].name}" (${d.cards.length} cards)`;

} else if (payload.type === 'cards-for-deck') {
  const targetId = payload.targetDeckId;
  if (typeof targetId !== 'string') fail('cards-for-deck missing targetDeckId.');
  const target = data.decks.find(x => x.id === targetId);
  if (!target) fail(`Target deck "${targetId}" not found in library.`);
  const cards = Array.isArray(payload.cards) ? payload.cards : [];
  const scenarios = payload.scenarios && typeof payload.scenarios === 'object' ? payload.scenarios : {};
  if (cards.length === 0 && Object.keys(scenarios).length === 0) fail('No cards or subjects in submission.');
  if (cards.length > LIMITS.cardsPerSubmit) fail(`Too many cards (max ${LIMITS.cardsPerSubmit}).`);
  if (Object.keys(scenarios).length > LIMITS.subjectsPerSubmit) fail(`Too many subjects (max ${LIMITS.subjectsPerSubmit}).`);

  let addedSubjects = 0;
  for (const [k, v] of Object.entries(scenarios)) {
    const ke = checkSubjectKey(k); if (ke) fail(ke);
    if (!v || typeof v !== 'object') fail(`subject "${k}" malformed.`);
    const le = checkString(v.label, LIMITS.title, `subject "${k}" label`); if (le) fail(le);
    const ce = checkColor(v.color); if (ce) fail(`subject "${k}": ${ce}`);
    if (!target.scenarios[k]) addedSubjects++;
    target.scenarios[k] = { label: htmlEscape(v.label.trim()), color: v.color.toLowerCase() };
  }

  for (const c of cards) {
    if (!c.scn || !(c.scn in target.scenarios)) fail(`card uses unknown subject "${c.scn}".`);
    const err = sanitizeCard(c);
    if (err) fail(`card ${c.id || '(no id)'}: ${err}`);
  }

  const usedIds = new Set(target.cards.map(c => c.id));
  cards.forEach((c, i) => {
    let cid = (typeof c.id === 'string' && /^[A-Za-z0-9-_]{1,60}$/.test(c.id)) ? c.id : `${targetId}-u${Date.now().toString(36)}-${i}`;
    while (usedIds.has(cid)) cid = `${targetId}-u${Math.random().toString(36).slice(2, 7)}`;
    c.id = cid;
    usedIds.add(cid);
    target.cards.push(serializeCard(c));
  });

  summary = `${cards.length} card(s) and ${addedSubjects} new subject(s) added to **${target.name}**.`;
  summaryShort = `Add ${cards.length} cards to "${target.name}"`;

} else {
  fail(`Unknown submission type "${payload.type}". Expected "new-deck" or "cards-for-deck".`);
}

data.updated = new Date().toISOString().slice(0, 10);
fs.writeFileSync(decksPath, JSON.stringify(data, null, 2) + '\n');

execSync('git config user.name "submission-bot"');
execSync('git config user.email "noreply@github.com"');

const branch = `submission/${ISSUE_NUMBER}-${Date.now().toString(36)}`;
execSync(`git checkout -b ${branch}`);
execSync(`git add ${decksPath}`);

const commitTitle = `Submission #${ISSUE_NUMBER}: ${summaryShort}`;
const commitBody = `${summary}\n\nFrom @${ISSUE_USER}, issue #${ISSUE_NUMBER}.`;
execSync(`git commit -m ${JSON.stringify(commitTitle)} -m ${JSON.stringify(commitBody)}`);
execSync(`git push origin ${branch}`);

const prBody = `${summary}\n\nAuto-merged from issue #${ISSUE_NUMBER} by @${ISSUE_USER}.\n\nCloses #${ISSUE_NUMBER}`;
execSync(`gh pr create --title ${JSON.stringify(commitTitle)} --body ${JSON.stringify(prBody)} --base main --head ${branch}`, { stdio: 'inherit' });
try {
  execSync(`gh pr merge ${branch} --auto --squash --delete-branch`, { stdio: 'inherit' });
} catch (e) {
  // Auto-merge may be disabled; fall back to direct merge
  execSync(`gh pr merge ${branch} --squash --delete-branch`, { stdio: 'inherit' });
}

ok(summary);
