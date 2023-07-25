

<div align="center">
<h1>Autochessia</h1>
<p>Fully on chain auto chess</p>
</div>

--------

Autochessia is a auto chess game, but runs fully on chain and write via MUD and solidity. Believing fully on-chain game would brings the next generation UGC paradigm, we make this game and try to make it extensible.

## Get Start

Require:

- pnpm
- foundry

Install dependencies

```bash
pnpm install
```

config default `.env`

```shell
cp packages/client/.env.example packages/client/.env
cp packages/contracts/.env.template packages/contracts/.env
```

run local development and preview

```bash
pnpm dev
```


## Feature

- waiting room and match
- buy, sell and place your hero
- income
- experience
- automatic routing and attack
- support 2 players in a game


## Todo

- [x] SnapSync
- [x] Lobby Matchmaking 
- [x] Quit Game 
- [ ] Multiplayer 
- [ ] Custom Rooms
- [ ] Damage Display
- [ ] Synthesis Tips 
- [ ] Racial Buffs
- [ ] Skills
- [ ] Items
- [ ] Movement Animation Completion 
- [ ] Attack Animations
- [ ] Hotkey Controls
- [ ] Full Auto Tick
- [ ] Beginner Guidance 
- [ ] Deployed on the l2 test network
- [ ] Account Abstraction
- [ ] Neutral Monsters




## Technical Highlight

- JPS auto routing
- pseudo random number

## Author

- @ClaudeZsb
- @aLIEzsss4
- @noyyyy

## Contribute

This repo contains all the source code of AutoChessia, and we welcome pull requests at any time. If you have any ideas for new features or modifications, we are happy to discuss them with you.

Your feedback is very important to us. Whether it's code contributions or product suggestions, we sincerely want to hear your thoughts. Let's work together to make AutoChessia more powerful and user-friendly!

If you encounter any issues during code contribution or usage, please feel free to reach out to us as well.

Thank you for supporting AutoChessia! We look forward to having you on board!
 [join our Discord]( https://discord.gg/Qget5JQHtr).

### Local development setup

!!!
The following steps are only necessary if you want to contribute to AutoChessia. To use AutoChessia in your project, install the [packages](#packages) from pnpm

1. Install the foundry toolkit (required to build and test AutoChessia solidity packages): [https://getfoundry.sh/](https://getfoundry.sh/)

2. Install pnpm

```
npm install pnpm --global
```

 
3. Clone the AutoChessia monorepo

```
git clone https://github.com/HelheimLabs/autochessia 
```

4. Install AutoChessia dependencies and setup local environment
```
cd autochessia && pnpm install
```

### Pull requests

AutoChessia follows the [conventional commit specification](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages and PR titles. Please keep the scope of your PR small (rather open multiple small PRs than one huge PR) and follow the conventional commit spec.

## Community support

[Join our Discord](https://discord.gg/Qget5JQHtr) to get support and connect with the community!


## License

Proud to be open-source and licensed under [AGPL-3.0](./LICENSE)
