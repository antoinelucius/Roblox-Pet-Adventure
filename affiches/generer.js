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

const DEFS = `<defs>
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

// ---------- affiches ----------
const P = {};

// 1. Les trois pets dans la prairie
P["affiche-1-pets"] = [1920, 1080, `
	<rect width="1920" height="1080" fill="url(#sky)"/>${rays(960, 620, 18, 0.16)}
	${hills(640, "#3fd04f", "#22a64a")}
	${coin(620, 560, 0.9)}${coin(1330, 600, 0.9)}${coin(1640, 300, 0.8)}${coin(300, 330, 0.8)}
	${sparkle(520, 420, 1)}${sparkle(1400, 430, 1.2)}${sparkle(100, 200, 0.8)}${sparkle(1840, 150, 0.9)}
	${shadow(290, 985, 250)}${shadow(1640, 985, 260)}${shadow(960, 1020, 330)}
	${g(290, 770, 0.95, pet("fox", "#ff9a2e"), -5)}
	${g(1640, 850, 1.05, slime("#4fe07a"), 5)}
	${g(960, 750, 1.15, pet("dragon", "#9a5bff", { wing: "#ff5fc8" }))}
	${vignette(1920, 1080)}${title(960, 250, 250)}`];

// 2. Le gros oeuf qui s'ouvre
P["affiche-2-oeuf"] = [1920, 1080, `
	<rect width="1920" height="1080" fill="url(#violet)"/>${rays(960, 640, 20, 0.14)}
	<circle cx="960" cy="640" r="620" fill="url(#glow)"/>${rays(960, 640, 10, 0.35, "#fff7b0")}
	<circle cx="960" cy="640" r="430" fill="url(#glow)"/>
	${shadow(330, 1000, 190)}${shadow(1590, 1000, 190)}${shadow(960, 1030, 300)}
	${g(330, 800, 0.72, egg("#4fa3ff"), -10)}
	${g(1590, 800, 0.72, egg("#ff5a3c", { spot: "#ffb03a" }), 10)}
	${g(960, 690, 1.28, egg("#ffc928", { crack: true, spot: "#fff08a" }), 4)}
	${sparkle(620, 520, 1.6)}${sparkle(1320, 480, 1.9)}${sparkle(1250, 900, 1.2)}${sparkle(660, 880, 1.1)}${sparkle(150, 480, 1)}${sparkle(1780, 470, 1)}
	${g(560, 700, 1, `<text font-family="Luckiest Guy" font-size="200" text-anchor="middle" fill="#fff" stroke="${INK}" stroke-width="34" paint-order="stroke" stroke-linejoin="round">?</text>`, -14)}
	${g(1370, 760, 1, `<text font-family="Luckiest Guy" font-size="240" text-anchor="middle" fill="#fff" stroke="${INK}" stroke-width="36" paint-order="stroke" stroke-linejoin="round">?</text>`, 12)}
	${vignette(1920, 1080)}${title(960, 240, 240, -2)}`];

// 3. Les trois mondes
P["affiche-3-mondes"] = [1920, 1080, `
	<clipPath id="w1"><path d="M0,0 H720 L560,1080 H0Z"/></clipPath>
	<clipPath id="w2"><path d="M720,0 H1360 L1200,1080 H560Z"/></clipPath>
	<clipPath id="w3"><path d="M1360,0 H1920 V1080 H1200Z"/></clipPath>
	<g clip-path="url(#w1)"><rect width="1920" height="1080" fill="url(#sky)"/>${rays(320, 700, 14, 0.15)}${hills(700, "#3fd04f", "#22a64a")}
		${shadow(320, 985, 230)}${g(320, 820, 1.05, slime("#4fe07a"), -4)}</g>
	<g clip-path="url(#w2)"><rect width="1920" height="1080" fill="url(#lava)"/>${rays(960, 700, 14, 0.12, "#ffd23a")}
		<path d="M560,800 L760,520 L860,640 L1000,460 L1160,700 L1360,560 V1080 H560Z" fill="#3a1020"/>
		<path d="M1000,460 L960,560 L1000,600 L1040,540Z" fill="#ffb01f"/>
		<path d="M480,930 Q800,860 1100,920 T1500,900 V1080 H480Z" fill="#ff8a1a"/>
		${shadow(950, 1000, 250)}${g(950, 760, 1, pet("dragon", "#ff4a1f", { wing: "#ffb01f", belly: "#ffd75a" }))}</g>
	<g clip-path="url(#w3)"><rect width="1920" height="1080" fill="url(#space)"/>${stars(7, 90, 1920, 1080)}${rays(1580, 700, 14, 0.08)}
		<circle cx="1730" cy="380" r="90" fill="#ffe9a8"/><circle cx="1700" cy="360" r="20" fill="#e8c878"/><circle cx="1760" cy="410" r="14" fill="#e8c878"/>
		<path d="M1100,960 Q1500,880 1920,950 V1080 H1100Z" fill="#3b1a8f"/>
		${shadow(1580, 1000, 240)}${g(1580, 770, 1, pet("wolf", "#5a8bff", { belly: "#cfe0ff" }), 4)}
		${sparkle(1420, 520, 1)}${sparkle(1850, 620, 0.8)}</g>
	<path d="M720,0 L560,1080" stroke="#fff" stroke-width="22"/><path d="M1360,0 L1200,1080" stroke="#fff" stroke-width="22"/>
	<path d="M720,0 L560,1080 M1360,0 L1200,1080" stroke="${INK}" stroke-width="8" fill="none" opacity="0"/>
	${vignette(1920, 1080)}${title(960, 245, 235, -2)}`];

// 4. Le pet secret
P["affiche-4-secret"] = [1920, 1080, `
	<rect width="1920" height="1080" fill="url(#space)"/>${stars(3, 120, 1920, 1080)}${rays(1240, 640, 18, 0.07)}
	<circle cx="1240" cy="640" r="640" fill="url(#glow)" opacity=".8"/>
	<g transform="translate(1240 640) scale(1.45)" style="filter:brightness(0) drop-shadow(0 0 22px #fff36b) drop-shadow(0 0 60px #ffb01f)">${pet("dragon", "#9a5bff")}</g>
	${g(1240, 720, 1, `<text font-family="Luckiest Guy" font-size="380" text-anchor="middle" fill="url(#gold)" stroke="#fff" stroke-width="22" paint-order="stroke" stroke-linejoin="round">?</text>`)}
	${shadow(400, 1010, 200)}${shadow(160, 990, 130)}
	${g(170, 880, 0.55, slime("#4fe07a"), -6)}
	${g(420, 830, 0.8, pet("fox", "#ff9a2e"), 4)}
	${sparkle(700, 560, 1.4, "#fff7b0")}${sparkle(1780, 300, 1.3, "#fff7b0")}${sparkle(1820, 860, 1, "#fff7b0")}${sparkle(820, 930, 0.9, "#fff7b0")}
	${vignette(1920, 1080)}${title(560, 250, 215, -4, false)}`];

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
