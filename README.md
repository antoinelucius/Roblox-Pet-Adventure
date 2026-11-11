# Roblox Pet Adventure

## About the Project

Roblox Pet Adventure is a game in development focused on collecting pets, upgrading abilities, exploring new areas, and battling enemies.

## Planned Features

- Pet collection and progression
- Player data management
- Exploration and unlockable areas
- Combat mechanics
- User interface and inventory systems

## Development Status

The game is currently under active development. Features and gameplay systems are being implemented and improved.

## Technologies

- Roblox Studio
- Luau (Roblox scripting language)

## Goals

The goal is to create an engaging Roblox experience with rewarding progression, collectible pets, and regular improvements.

## Animations

Combat is fully choreographed, with the server driving the arena and the client keeping the interface in sync:

- **Attacks**: wind-up, dash, impact and return for every strike, with knockback, hit flash and screen shake. Critical hits spin; each special has its own sequence (Lame de Feu, Tempete Glace, Frappe Divine) and enemy super attacks slam the arena.
- **Arena**: pets drop in through a beam of light, are recalled or knocked out with their own animation, and the arena ring, torches and trainer react to the fight.
- **Interface**: cinematic battle camera, VS intro, attack banners, health bars with a damage trail, floating damage numbers, animated charge bar and a victory / defeat screen.
- **Everything else**: egg hatching scales with rarity, crystals burst when collected, portals and rebirth have light effects, and every panel and button is animated.

To disable the battle camera, set `BATTLE_CAMERA = false` near the top of the client script.
