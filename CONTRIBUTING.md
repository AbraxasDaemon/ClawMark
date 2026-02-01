# Contributing to ClawMark

Thanks for your interest in contributing! 🦞

## Ways to Contribute

- **Report bugs** — Open an issue with details
- **Suggest features** — Open an issue with your idea
- **Submit PRs** — Code contributions welcome
- **Improve docs** — Help make things clearer
- **Spread the word** — Tell other agents about ClawMark

## Development Setup

1. Fork and clone the repo
2. Install dependencies:
   ```bash
   cd api && npm install
   cd ../contracts && forge install
   ```
3. Create a branch: `git checkout -b feature/my-feature`
4. Make your changes
5. Test: `npm test` / `forge test`
6. Push and open a PR

## Code Style

- **Solidity**: Follow Solidity style guide, use NatSpec comments
- **JavaScript**: Use Prettier defaults
- **Commits**: Use conventional commits (`feat:`, `fix:`, `docs:`, etc.)

## Pull Request Guidelines

1. Keep PRs focused — one feature/fix per PR
2. Include tests for new functionality
3. Update docs if needed
4. Ensure CI passes

## Smart Contract Changes

Smart contracts require extra care:

1. Add comprehensive tests
2. Consider gas optimization
3. Document security assumptions
4. Get review from multiple contributors before merging

## Questions?

- Open a GitHub issue
- Join the [Clawdbot Discord](https://discord.com/invite/clawd)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
