// Genere les affiches Roblox de MAGIC PETS (miniatures 1920x1080 + icone 512x512).
// Usage : node affiches/generer.js <dossier-des-polices>
// Le dossier doit contenir luckiest-guy-latin-400-normal.woff2 (paquet npm @fontsource/luckiest-guy).
const { chromium } = require("playwright");
const fs = require("fs");
const path = require("path");

const FONT_DIR = path.resolve(process.argv[2] || ".");
const OUT = __dirname;
const INK = "#24103f";
const GAME = ["MAGIC", "PETS"];

// ---------- couleurs ----------
const hex = (c) => c.match(/\w\w/g).map((h) => parseInt(h, 16));
const mix = (c, t, k) => {
	const a = hex(c), b = hex(t);
	return "#" + a.map((v, i) => Math.round(v + (b[i] - v) * k).toString(16).padStart(2, "0")).join("");
};
const dark = (c, k = 0.25) => mix(c, "#1a0b3a", k);
const light = (c, k = 0.45) => mix(c, "#ffffff", k);

// ---------- briques ----------
const g = (x, y, s, inner, rot = 0) => `<g transform="translate(${x} ${y}) rotate(${rot}) scale(${s})">${inner}</g>`;
const O = `stroke="${INK}" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"`;

function eyes(dx = 85, y = -20, col = "#1b1030") {
	return [-1, 1].map((k) => `
		<ellipse cx="${k * dx}" cy="${y}" rx="44" ry="54" fill="${col}"/>
		<circle cx="${k * dx - 14}" cy="${y - 20}" r="17" fill="#fff"/>
		<circle cx="${k * dx + 14}" cy="${y + 20}" r="8" fill="#fff"/>`).join("");
}
const cheeks = (dx = 142, y = 48) => [-1, 1].map((k) => `<ellipse cx="${k * dx}" cy="${y}" rx="30" ry="20" fill="#ff7fb0" opacity=".75"/>`).join("");

// Pet "cube" facon simulateur : kind = dragon | fox | wolf | golem
function pet(kind, c, o = {}) {
	const d = dark(c), l = o.belly || light(c);
	const horn = o.horn || "#fff3c4";
	let back = "", top = "", face = "";

	if (kind === "dragon") {
		const wing = (k) => `<g transform="scale(${k} 1)">
			<path d="M90,120 Q300,-110 400,60 Q340,60 330,140 Q280,110 260,190 Q210,150 90,220Z" fill="${o.wing || d}" ${O}/>
			<path d="M110,150 Q260,0 345,70" fill="none" stroke="${INK}" stroke-width="7" opacity=".5"/></g>`;
		back = wing(1) + wing(-1) +
			`<path d="M90,225 Q250,250 255,150" fill="none" stroke="${INK}" stroke-width="58" stroke-linecap="round"/>
			 <path d="M90,225 Q250,250 255,150" fill="none" stroke="${c}" stroke-width="36" stroke-linecap="round"/>
			 <path d="M255,150 l-38,-18 l38,-62 l38,62Z" fill="${horn}" ${O}/>`;
		top = [-1, 1].map((k) => `<path d="M${k * 70},-160 L${k * 175},-300 L${k * 150},-150Z" fill="${horn}" ${O}/>`).join("") +
			`<path d="M-40,-165 L0,-225 L40,-165Z" fill="${d}" ${O}/>`;
		face = `<ellipse cx="-22" cy="38" rx="7" ry="10" fill="${INK}"/><ellipse cx="22" cy="38" rx="7" ry="10" fill="${INK}"/>
			<path d="M-45,72 Q0,108 45,72" fill="none" ${O}/>
			<path d="M22,84 l12,24 l12,-30Z" fill="#fff" stroke="${INK}" stroke-width="6" stroke-linejoin="round"/>`;
	} else if (kind === "fox" || kind === "wolf") {
		back = `<path d="M80,230 Q300,260 270,60 Q200,90 170,170Z" fill="${c}" ${O}/>
			<path d="M270,60 Q282,125 250,150 Q215,110 270,60Z" fill="#fff"/>`;
		top = [-1, 1].map((k) => `<path d="M${k * 60},-160 L${k * 160},-310 L${k * 185},-120Z" fill="${c}" ${O}/>
			<path d="M${k * 100},-170 L${k * 152},-255 L${k * 165},-160Z" fill="${kind === "fox" ? "#fff" : l}"/>`).join("");
		face = `<path d="M-190,40 Q-100,10 0,60 Q100,10 190,40 L190,70 Q190,130 120,130 L-120,130 Q-190,130 -190,70Z" fill="#fff"/>
			<ellipse cx="0" cy="48" rx="20" ry="14" fill="${INK}"/>
			<path d="M-34,78 Q-17,98 0,78 Q17,98 34,78" fill="none" ${O} stroke-width="9"/>`;
	} else if (kind === "golem") {
		top = `<path d="M-150,-165 q20,-50 60,-10 q30,-60 70,-5 q30,-50 60,0 q40,-45 70,15Z" fill="${o.moss || "#58d66a"}" ${O}/>`;
		face = `<path d="M-45,70 h90" fill="none" ${O}/>`;
	}

	return `${back}
		<rect x="-110" y="90" width="220" height="175" rx="42" fill="${c}" ${O}/>
		<rect x="-66" y="128" width="132" height="137" rx="34" fill="${l}"/>
		<rect x="-128" y="232" width="92" height="52" rx="22" fill="${d}" ${O}/>
		<rect x="36" y="232" width="92" height="52" rx="22" fill="${d}" ${O}/>
		${top}
		<rect x="-190" y="-170" width="380" height="300" rx="72" fill="${c}" ${O}/>
		<clipPath id="h${kind}${c.slice(1)}"><rect x="-184" y="-164" width="368" height="288" rx="66"/></clipPath>
		<g clip-path="url(#h${kind}${c.slice(1)})">
			<rect x="-190" y="60" width="380" height="80" fill="${d}" opacity=".35"/>
			${kind === "fox" || kind === "wolf" ? face : ""}
			<path d="M-160,-150 h180 q-150,20 -180,130Z" fill="#fff" opacity=".28"/>
		</g>
		<rect x="-190" y="-170" width="380" height="300" rx="72" fill="none" ${O}/>
		${kind === "fox" || kind === "wolf" ? "" : face}
		${eyes()}${cheeks()}`;
}

function slime(c) {
	const body = "M-200,120 Q-215,-170 0,-180 Q215,-170 200,120 Q200,160 160,160 L-160,160 Q-200,160 -200,120Z";
	return `<path d="${body}" fill="${c}" ${O}/>
		<path d="M-150,40 Q-150,-120 -20,-140 Q-110,-90 -120,40Z" fill="#fff" opacity=".45"/>
		<path d="M-185,110 Q0,150 185,110 L185,150 L-185,150Z" fill="${dark(c)}" opacity=".4"/>
		<path d="${body}" fill="none" ${O}/>
		${eyes(80, -10)}${cheeks(140, 55)}
		<path d="M-38,58 Q0,105 38,58Z" fill="${INK}" ${O} stroke-width="8"/>`;
}

function egg(c, o = {}) {
	const shape = "M0,-250 C130,-250 200,-40 200,60 C200,190 110,250 0,250 C-110,250 -200,190 -200,60 C-200,-40 -130,-250 0,-250Z";
	const id = "e" + c.slice(1) + (o.crack ? "c" : "");
	const spots = [[-90, -60, 44], [80, 20, 56], [-50, 130, 40], [70, -150, 30], [-130, 60, 24], [110, 150, 30]]
		.map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${o.spot || light(c, 0.5)}"/>`).join("");
	const crack = o.crack ? `<path d="M-200,10 L-120,-40 L-60,30 L0,-45 L60,30 L120,-40 L200,10" fill="none" stroke="${INK}" stroke-width="26" stroke-linejoin="round"/>
		<path d="M-200,10 L-120,-40 L-60,30 L0,-45 L60,30 L120,-40 L200,10" fill="none" stroke="#fffbe0" stroke-width="12" stroke-linejoin="round"/>` : "";
	return `<path d="${shape}" fill="${c}" ${O}/>
		<clipPath id="${id}"><path d="${shape}"/></clipPath>
		<g clip-path="url(#${id})">${spots}
			<path d="M40,-260 C240,-200 240,200 0,260 L260,260 L260,-260Z" fill="${dark(c, 0.35)}" opacity=".35"/>
			<ellipse cx="-90" cy="-120" rx="34" ry="70" fill="#fff" opacity=".55" transform="rotate(22 -90 -120)"/>
			${crack}</g>
		<path d="${shape}" fill="none" ${O}/>`;
}

const sparkle = (x, y, s, c = "#fff") => g(x, y, s, `<path d="M0,-50 Q8,-8 50,0 Q8,8 0,50 Q-8,8 -50,0 Q-8,-8 0,-50Z" fill="${c}"/>`);
const coin = (x, y, s) => g(x, y, s, `<circle r="50" fill="#ffc21a" ${O} stroke-width="10"/><circle r="32" fill="#ffe36b"/><path d="M-10,-18 v36 M10,-18 v36" stroke="#e39a00" stroke-width="9" stroke-linecap="round"/>`);

function rays(cx, cy, n = 16, op = 0.13, col = "#fff") {
	let s = "";
	for (let i = 0; i < n; i++) {
		const a = (i / n) * Math.PI * 2, b = a + Math.PI / n, R = 2600;
		s += `<path d="M${cx},${cy} L${cx + Math.cos(a) * R},${cy + Math.sin(a) * R} L${cx + Math.cos(b) * R},${cy + Math.sin(b) * R}Z" fill="${col}" opacity="${op}"/>`;
	}
	return s;
}

function title(x, y, size, rot = -3, oneLine = true) {
	const layer = (extra, fills) => oneLine
		? `<text x="0" y="0" ${extra}><tspan ${fills[0]}>${GAME[0]}</tspan><tspan dx="${size * 0.22}" ${fills[1]}>${GAME[1]}</tspan></text>`
		: `<text x="0" y="0" ${extra} ${fills[0]}>${GAME[0]}</text><text x="0" y="${size * 0.92}" ${extra} ${fills[1]}>${GAME[1]}</text>`;
	const base = `font-family="Luckiest Guy" font-size="${size}" text-anchor="middle" paint-order="stroke" stroke-linejoin="round"`;
	const k = size / 220;
	return `<g transform="translate(${x} ${y}) rotate(${rot})">
		<g transform="translate(0 ${18 * k})">${layer(`${base} stroke="${INK}" stroke-width="${64 * k}"`, [`fill="${INK}"`, `fill="${INK}"`])}</g>
		${layer(`${base} stroke="${INK}" stroke-width="${64 * k}"`, [`fill="${INK}"`, `fill="${INK}"`])}
		${layer(`${base} stroke="#fff" stroke-width="${26 * k}"`, [`fill="url(#gold)"`, `fill="url(#cyan)"`])}
	</g>`;
}

let DEFS = `<defs>
	<linearGradient id="gold" x1="0" y1="0" x2="0" y2="1"><stop offset=".15" stop-color="#fff36b"/><stop offset=".85" stop-color="#ff9a1f"/></linearGradient>
	<linearGradient id="cyan" x1="0" y1="0" x2="0" y2="1"><stop offset=".15" stop-color="#ff9df0"/><stop offset=".85" stop-color="#e93cc0"/></linearGradient>
	<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1e9bff"/><stop offset="1" stop-color="#8fe3ff"/></linearGradient>
	<linearGradient id="violet" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a2cf0"/><stop offset="1" stop-color="#ff5fc8"/></linearGradient>
	<linearGradient id="lava" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7a1010"/><stop offset="1" stop-color="#ff7a1a"/></linearGradient>
	<linearGradient id="space" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#150a3d"/><stop offset="1" stop-color="#6b2bd6"/></linearGradient>
	<radialGradient id="glow"><stop offset="0" stop-color="#fffbd0"/><stop offset=".45" stop-color="#ffe45c" stop-opacity=".75"/><stop offset="1" stop-color="#ffe45c" stop-opacity="0"/></radialGradient>
	<radialGradient id="vig"><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#1a0b3a" stop-opacity=".3"/></radialGradient>
</defs>`;

const hills = (y, c1, c2) => `
	<path d="M0,${y + 60} Q480,${y - 120} 960,${y + 30} T1920,${y} V1080 H0Z" fill="${c2}"/>
	<path d="M0,${y + 170} Q500,${y + 40} 1000,${y + 150} T1920,${y + 120} V1080 H0Z" fill="${c1}"/>`;
const shadow = (x, y, rx) => `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${rx * 0.16}" fill="#000" opacity=".22"/>`;
const stars = (seed, n, w, h) => {
	let s = "", r = seed;
	const rnd = () => ((r = (r * 9301 + 49297) % 233280) / 233280);
	for (let i = 0; i < n; i++) s += `<circle cx="${rnd() * w}" cy="${rnd() * h}" r="${2 + rnd() * 5}" fill="#fff" opacity="${0.4 + rnd() * 0.6}"/>`;
	return s;
};
const vignette = (w, h) => `<rect width="${w}" height="${h}" fill="url(#vig)"/>`;

// ---------- decor en cubes ----------
function ground(hz, ca, cb, cx = 960) {
	const K = 420, T = 0.45, W = 1920, H = 1080;
	let s = `<rect x="0" y="${hz}" width="${W}" height="${H - hz}" fill="${mix(ca, cb, 0.5)}"/>`;
	for (let i = 0; i < 42; i++) {
		const Z0 = 0.6 + i * T, Z1 = Z0 + T, y0 = hz + K / Z0, y1 = hz + K / Z1;
		if (y1 > H) continue;
		const jm = Math.ceil((W / 2 + Math.abs(cx - 960)) * Z1 / K / T) + 1;
		for (let j = -jm; j < jm; j++) {
			if ((i + j) & 1) continue;
			const a = cx + j * T * K / Z0, b = cx + (j + 1) * T * K / Z0, c = cx + (j + 1) * T * K / Z1, d = cx + j * T * K / Z1;
			if (Math.max(a, b, c, d) < 0 || Math.min(a, b, c, d) > W) continue;
			s += `<path d="M${a.toFixed(1)},${y0.toFixed(1)} L${b.toFixed(1)},${y0.toFixed(1)} L${c.toFixed(1)},${y1.toFixed(1)} L${d.toFixed(1)},${y1.toFixed(1)}Z" fill="${ca}"/>`;
		}
	}
	return s + `<rect x="0" y="${hz}" width="${W}" height="90" fill="url(#haze)"/>`;
}
function box(x, y, w, h, d, c) {
	const o = `stroke="${INK}" stroke-width="5" stroke-linejoin="round"`;
	return `<path d="M${x},${y} l${d},${-d * 0.5} h${w} l${-d},${d * 0.5}Z" fill="${light(c, 0.3)}" ${o}/>
		<path d="M${x + w},${y} l${d},${-d * 0.5} v${h} l${-d},${d * 0.5}Z" fill="${dark(c, 0.3)}" ${o}/>
		<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${c}" ${o}/>`;
}
const tree = (x, y, s, leaf = "#2fb84a", trunk = "#8a5a33") => g(x, y, s,
	box(-22, -70, 44, 70, 20, trunk) + box(-95, -130, 190, 60, 50, leaf) + box(-70, -190, 140, 60, 40, leaf) + box(-42, -245, 84, 55, 28, leaf));
const cloud = (x, y, s, op = 0.95) => g(x, y, s, `<g fill="#fff" opacity="${op}"><circle cx="-90" cy="0" r="55"/><circle cx="-20" cy="-40" r="75"/><circle cx="70" cy="-10" r="62"/><rect x="-145" y="0" width="277" height="55" rx="27"/></g>`);
const forest = (hz, list, leaf, trunk) => list.map(([x, s]) => tree(x, hz + 14 + s * 20, s, leaf, trunk)).join("");

// ---------- personnage en blocs ----------
function avatar(p = {}) {
	const skin = "#ffd23a", shirt = "#1f8fff", pants = "#7ed321";
	const part = (x, y, w, h, c, rot, px, py, rx = 14) => `<g transform="rotate(${rot} ${px} ${py})">
		<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${rx}" fill="${c}" ${O}/>
		<rect x="${x + w * 0.68}" y="${y + 6}" width="${w * 0.32 - 6}" height="${h - 12}" rx="8" fill="#000" opacity=".13"/></g>`;
	return `<g transform="rotate(${p.lean || 0})">
		${part(-196, -100, 96, 200, skin, p.armL || 0, -148, -70)}
		${part(-100, 100, 97, 200, pants, p.legL || 0, -52, 110)}
		${part(3, 100, 97, 200, pants, p.legR || 0, 52, 110)}
		${part(-100, -100, 200, 200, shirt, 0, 0, 0)}
		<g transform="rotate(${p.head || 0} 0 -110)">
			<rect x="-78" y="-250" width="156" height="140" rx="38" fill="${skin}" ${O}/>
			<path d="M-66,-238 h80 q-66,10 -80,60Z" fill="#fff" opacity=".35"/>
			<ellipse cx="-30" cy="-192" rx="10" ry="16" fill="${INK}"/><ellipse cx="30" cy="-192" rx="10" ry="16" fill="${INK}"/>
			${p.open ? `<path d="M-36,-164 Q0,-112 36,-164Z" fill="${INK}" ${O} stroke-width="8"/>` : `<path d="M-38,-162 Q0,-128 38,-162" fill="none" ${O} stroke-width="10"/>`}
		</g>
		${part(100, -100, 96, 200, skin, p.armR || 0, 148, -70)}
	</g>`;
}

function crystal(c, c2) {
	const one = (col) => `<path d="M0,-270 L95,-170 L95,110 L0,190 L-95,110 L-95,-170Z" fill="${col}" ${O}/>
		<path d="M0,-270 L-95,-170 L-95,110 L0,190Z" fill="${light(col, 0.4)}"/>
		<path d="M0,-270 L95,-170 L0,-120 L-95,-170Z" fill="${light(col, 0.7)}"/>
		<path d="M0,-120 V190" stroke="${dark(col, 0.2)}" stroke-width="6"/>
		<path d="M-62,-110 v150" stroke="#fff" stroke-width="16" stroke-linecap="round" opacity=".7"/>
		<path d="M0,-270 L95,-170 L95,110 L0,190 L-95,110 L-95,-170Z" fill="none" ${O}/>`;
	return `${g(-150, 60, 0.62, one(c2), -28)}${g(160, 70, 0.7, one(c2), 26)}${one(c)}
		<path d="M-250,170 l60,-50 l90,20 l100,-30 l110,30 l80,-20 l60,50 l-40,50 h-420Z" fill="#6c5a8c" ${O}/>`;
}
const burst = (x, y, r, n = 14, c = "#fff", op = 0.9) => {
	let d = "";
	for (let i = 0; i < n * 2; i++) { const a = (i / (n * 2)) * Math.PI * 2, R = i % 2 ? r * 0.55 : r * (0.85 + 0.15 * ((i * 7) % 5) / 4); d += `${i ? "L" : "M"}${(x + Math.cos(a) * R).toFixed(0)},${(y + Math.sin(a) * R).toFixed(0)}`; }
	return `<path d="${d}Z" fill="${c}" opacity="${op}"/>`;
};
const shard = (x, y, s, rot, c) => g(x, y, s, `<path d="M0,-40 L26,0 L0,40 L-26,0Z" fill="${c}" ${O} stroke-width="9"/><path d="M0,-40 L-26,0 L0,40Z" fill="#fff" opacity=".5"/>`, rot);
const pop = (t, x, y, size, rot = -6, fill = "#fff") => {
	const b = `font-family="Luckiest Guy" font-size="${size}" text-anchor="middle" paint-order="stroke" stroke-linejoin="round"`;
	return `<g transform="translate(${x} ${y}) rotate(${rot})">
		<text y="${size * 0.09}" ${b} fill="${INK}" stroke="${INK}" stroke-width="${size * 0.26}">${t}</text>
		<text ${b} fill="${fill}" stroke="${INK}" stroke-width="${size * 0.2}">${t}</text></g>`;
};
const arc = (x0, y0, x1, y1, h) => `<path d="M${x0},${y0} Q${(x0 + x1) / 2},${Math.min(y0, y1) - h} ${x1},${y1}" fill="none" stroke="#fff" stroke-width="16" stroke-linecap="round" opacity=".9"/>`;
const speed = (l) => l.map(([x, y, x2, y2, w]) => { const dx = y2 - y, dy = x - x2, n = Math.hypot(dx, dy) || 1; return `<path d="M${x + dx / n * w},${y + dy / n * w} L${x2},${y2} L${x - dx / n * w},${y - dy / n * w}Z" fill="#fff" opacity=".75"/>`; }).join("");
const stk = (inner) => `<g filter="url(#stk)">${inner}</g>`;

function eggHalf(c, spot, top) {
	const shape = "M0,-250 C130,-250 200,-40 200,60 C200,190 110,250 0,250 C-110,250 -200,190 -200,60 C-200,-40 -130,-250 0,-250Z";
	const zig = "-230,10 -150,-50 -80,25 0,-50 80,25 150,-50 230,10";
	const id = "eh" + c.slice(1) + (top ? "t" : "b");
	const spots = [[-90, -110, 40], [80, 90, 56], [-60, 150, 40], [70, -160, 30], [-140, 80, 24]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${spot}"/>`).join("");
	return `<clipPath id="${id}"><polygon points="${zig} 230,${top ? -300 : 300} -230,${top ? -300 : 300}"/></clipPath><clipPath id="${id}s"><path d="${shape}"/></clipPath>
		<g clip-path="url(#${id})"><path d="${shape}" fill="${c}"/><g clip-path="url(#${id}s)">${spots}
			<path d="M40,-260 C240,-200 240,200 0,260 L260,260 L260,-260Z" fill="${dark(c, 0.35)}" opacity=".35"/>
			<ellipse cx="-95" cy="-130" rx="30" ry="60" fill="#fff" opacity=".55" transform="rotate(22 -95 -130)"/></g>
			<path d="${shape}" fill="none" stroke="${INK}" stroke-width="24"/></g>
		<g clip-path="url(#${id}s)"><polyline points="${zig}" fill="none" stroke="${INK}" stroke-width="13" stroke-linejoin="round"/></g>`;
}

DEFS = DEFS.replace("</defs>", `
	<linearGradient id="haze" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".45"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
	<linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2aa5ff"/><stop offset="1" stop-color="#b6f0ff"/></linearGradient>
	<linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1b0a52"/><stop offset="1" stop-color="#b03cf0"/></linearGradient>
	<filter id="stk" x="-15%" y="-15%" width="130%" height="130%"><feMorphology in="SourceAlpha" operator="dilate" radius="9" result="d"/><feFlood flood-color="#fff"/><feComposite in2="d" operator="in" result="o"/><feMerge><feMergeNode in="o"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
	<filter id="cosmic"><feColorMatrix type="matrix" values=".9 0 0 0 0  0 .4 0 0 0  .4 .5 .9 0 0  0 0 0 1 0"/></filter>
</defs>`);

const TREES_L = [[60, 1.5], [250, 1.0], [470, 1.25], [700, 0.8], [880, 0.7]];
const TREES_R = [[1080, 0.75], [1280, 0.9], [1500, 1.2], [1700, 0.95], [1870, 1.5]];
const HZ = 430;

// ---------- affiches ----------
const P = {};

// 1. On ramasse un cristal : les pieces sautent vers le joueur
P["affiche-1-cristal"] = [1920, 1080, `
	<rect width="1920" height="1080" fill="url(#day)"/>
	${cloud(420, 150, 1.5)}${cloud(1250, 230, 1.9)}${cloud(1780, 110, 1.1)}${cloud(820, 300, 0.9, 0.7)}
	${forest(HZ, [...TREES_L, ...TREES_R])}
	${ground(HZ, "#48d657", "#36c04a", 700)}
	${shadow(330, 905, 190)}${shadow(110, 1005, 110)}
	${stk(g(110, 900, 0.42, pet("fox", "#ff9a2e"), -4))}
	${stk(g(330, 620, 0.92, avatar({ armR: -78, armL: 35, legL: 22, legR: -24, lean: 6 })))}
	${arc(1150, 760, 900, 800, 190)}${arc(900, 800, 700, 770, 130)}${arc(700, 770, 560, 600, 90)}
	${coin(1030, 650, 0.9)}${coin(800, 690, 0.75)}${coin(630, 660, 0.65)}
	${burst(900, 805, 46, 9)}${burst(700, 775, 36, 9)}
	${pop("+25", 1010, 520, 120, -8)}${pop("+25", 780, 590, 96, -6)}
	${burst(1400, 700, 520, 16, "#fff", 0.55)}${burst(1400, 700, 360, 14, "#fff7b0", 0.8)}
	${shadow(1400, 990, 380)}
	${stk(g(1400, 700, 1.55, crystal("#ff5fe0", "#4fc3ff"), 8))}
	${shard(1040, 900, 1.3, 30, "#ff5fe0")}${shard(1790, 880, 1.5, -20, "#4fc3ff")}${shard(1800, 420, 1.2, 15, "#ff5fe0")}
	${sparkle(1180, 480, 1.3)}${sparkle(1700, 600, 1.1)}${sparkle(1560, 250, 0.9)}
	${pop("+25", 1700, 300, 210, 8)}
	${speed([[0, 60, 520, 250, 14], [1920, 40, 1640, 110, 9]])}`];

// 2. Un oeuf s'ouvre : un dragon en sort
P["affiche-2-oeuf"] = [1920, 1080, `
	<rect width="1920" height="1080" fill="url(#day)"/>
	${cloud(900, 160, 1.6)}${cloud(1600, 240, 1.4)}${cloud(1250, 330, 0.9, 0.7)}
	${forest(HZ, [...TREES_L, ...TREES_R])}
	${ground(HZ, "#48d657", "#36c04a", 1250)}
	${shadow(1590, 800, 150)}${shadow(1340, 815, 80)}
	${stk(g(1590, 590, 0.62, avatar({ armR: -150, armL: 150, legL: 12, legR: -12, open: true })))}
	${stk(g(1340, 740, 0.3, slime("#4fe07a"), 5))}
	${pop("!", 1750, 400, 130, 12, "#ffe14a")}
	${burst(640, 600, 640, 18, "#fff", 0.5)}${burst(640, 600, 430, 16, "#fff7b0", 0.85)}
	${shadow(640, 1010, 380)}
	${stk(g(600, 215, 1.0, eggHalf("#ffc928", "#fff08a", true), -24))}
	${stk(g(660, 560, 1.15, pet("dragon", "#9a5bff", { wing: "#ff5fc8" }), 5))}
	${stk(g(650, 800, 1.5, eggHalf("#ffc928", "#fff08a", false), 5))}
	${shard(170, 420, 1.5, 30, "#ffc928")}${shard(1130, 380, 1.3, -30, "#ffc928")}${shard(1120, 900, 1.2, 50, "#ffc928")}${shard(130, 820, 1.1, -15, "#ffc928")}
	${sparkle(250, 180, 1.4)}${sparkle(1060, 640, 1.2)}${sparkle(980, 170, 1)}
	${speed([[1920, 60, 1380, 200, 14], [1920, 1040, 1500, 960, 12], [0, 1030, 300, 1000, 10], [0, 30, 260, 90, 9]])}`];

// 3. Avant / apres : +1 au debut, +80K avec le dragon primordial
const CUT = "1010,0 930,250 1000,300 900,610 970,660 880,1080";
P["affiche-3-evolution"] = [1920, 1080, `
	<clipPath id="cl"><polygon points="0,0 ${CUT} 0,1080"/></clipPath>
	<clipPath id="cr"><polygon points="1920,0 ${CUT} 1920,1080"/></clipPath>
	<g clip-path="url(#cl)">
		<rect width="1920" height="1080" fill="url(#day)"/>${cloud(700, 300, 1.2)}${cloud(80, 330, 1)}
		${forest(HZ, TREES_L)}${ground(HZ, "#48d657", "#36c04a", 960)}
		${shadow(250, 965, 150)}${stk(g(250, 850, 0.55, slime("#4fe07a"), -5))}
		${coin(520, 900, 0.8)}
		${stk(g(960, 620, 1.45, avatar({ armR: -25, armL: 25, legL: 12, legR: -12 })))}
	</g>
	<g clip-path="url(#cr)">
		<rect width="1920" height="1080" fill="url(#night)"/>${stars(11, 160, 1920, 600)}
		<g opacity=".8">${forest(HZ, TREES_R, "#7a2bd6", "#3a1470")}</g>${ground(HZ, "#a03cf5", "#7d24d8", 960)}
		<circle cx="1500" cy="720" r="520" fill="url(#glow)" opacity=".75"/>
		${stk(`<g filter="url(#cosmic)">${g(960, 620, 1.45, avatar({ armR: -25, armL: 25, legL: 12, legR: -12 }))}</g>`)}
		${shadow(1500, 1010, 330)}
		${stk(g(1500, 720, 1.1, pet("dragon", "#ffffff", { wing: "#ffd84a", horn: "#ffc21a", belly: "#fff3b0" }), 4))}
		${sparkle(1130, 560, 1.3, "#fff7b0")}${sparkle(1850, 520, 1.1, "#fff7b0")}${sparkle(1210, 940, 1, "#fff7b0")}${sparkle(1820, 930, 1.2, "#fff7b0")}
		${coin(1160, 800, 0.8)}${coin(1840, 720, 0.9)}${coin(1250, 430, 0.7)}
	</g>
	<polyline points="${CUT}" fill="none" stroke="#d9a8ff" stroke-width="34" stroke-linejoin="round" opacity=".6"/>
	<polyline points="${CUT}" fill="none" stroke="#fff" stroke-width="12" stroke-linejoin="round"/>
	${pop("+1", 300, 300, 300, -6)}
	${pop("+80K", 1470, 290, 290, 5, "url(#gold)")}`];

// 4. Les trois mondes
P["affiche-4-mondes"] = [1920, 1080, `
	<clipPath id="w1"><path d="M0,0 H720 L560,1080 H0Z"/></clipPath>
	<clipPath id="w2"><path d="M720,0 H1360 L1200,1080 H560Z"/></clipPath>
	<clipPath id="w3"><path d="M1360,0 H1920 V1080 H1200Z"/></clipPath>
	<g clip-path="url(#w1)"><rect width="1920" height="1080" fill="url(#day)"/>${cloud(200, 200, 1.3)}${cloud(560, 330, 0.9)}
		${forest(HZ, [[60, 1.4], [330, 1.0], [600, 1.2]])}${ground(HZ, "#48d657", "#36c04a", 320)}
		${shadow(300, 985, 200)}${stk(g(300, 830, 0.9, slime("#4fe07a"), -4))}${pop("+25", 300, 560, 150, -6)}</g>
	<g clip-path="url(#w2)"><rect width="1920" height="1080" fill="url(#lava)"/>
		<path d="M560,460 L760,250 L860,360 L1000,180 L1160,400 L1360,300 V500 H560Z" fill="#3a1020"/><path d="M1000,180 L950,290 L1000,330 L1050,270Z" fill="#ffb01f"/>
		${ground(HZ, "#ff7a1a", "#d9480f", 950)}
		${shadow(950, 1000, 260)}${stk(g(950, 790, 0.95, pet("dragon", "#ff4a1f", { wing: "#ffb01f", belly: "#ffd75a" })))}${pop("+200", 960, 380, 150, 4, "#ffe14a")}</g>
	<g clip-path="url(#w3)"><rect width="1920" height="1080" fill="url(#night)"/>${stars(7, 120, 1920, 600)}
		<circle cx="1760" cy="120" r="80" fill="#ffe9a8"/>
		${ground(HZ, "#a03cf5", "#7d24d8", 1580)}
		${shadow(1580, 1000, 240)}${stk(g(1580, 800, 0.95, pet("wolf", "#5a8bff", { belly: "#cfe0ff" }), 4))}${pop("+2000", 1600, 400, 150, 6, "url(#gold)")}</g>
	<path d="M720,0 L560,1080 M1360,0 L1200,1080" stroke="#fff" stroke-width="22"/>`];

// Icone carree (logo du jeu)
P["icone"] = [512, 512, `<g transform="scale(${512 / 1080})">
	<rect width="1080" height="1080" fill="url(#sky)"/>${rays(540, 520, 16, 0.18)}
	${g(540, 400, 1.55, pet("dragon", "#9a5bff", { wing: "#ff5fc8" }))}
	${sparkle(120, 140, 1.4)}${sparkle(960, 200, 1.2)}
	${title(540, 810, 225, -3, false)}</g>`];

(async () => {
	const font = fs.readFileSync(path.join(FONT_DIR, "luckiest-guy-latin-400-normal.woff2")).toString("base64");
	const browser = await chromium.launch();
	for (const [name, [w, h, body]] of Object.entries(P)) {
		const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
		await page.setContent(`<style>@font-face{font-family:"Luckiest Guy";src:url(data:font/woff2;base64,${font})}body{margin:0}svg{display:block}</style>
			<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${DEFS}${body}</svg>`);
		await page.evaluate(() => document.fonts.load('100px "Luckiest Guy"').then(() => document.fonts.ready));
		await page.screenshot({ path: path.join(OUT, name + ".png") });
		await page.close();
		console.log("ok", name);
	}
	await browser.close();
})();
