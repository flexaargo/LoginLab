import js from '@eslint/js';
import eslintConfigPrettier from 'eslint-config-prettier';
import prettierPlugin from 'eslint-plugin-prettier';
import tseslint from 'typescript-eslint';

export default [
  // Ignore generated stuff
  { ignores: ['dist/**', 'build/**', 'coverage/**', 'node_modules/**'] },

  // Base JS recommended rules
  js.configs.recommended,

  // TypeScript recommended rules
  ...tseslint.configs.recommended,

  // Prettier as an ESLint rule + disable conflicting formatting rules
  eslintConfigPrettier,
  {
    plugins: { prettier: prettierPlugin },
    rules: {
      'prettier/prettier': [
        'error',
        {
          tabWidth: 2,
          useTabs: false,
          singleQuote: true,
        },
      ],
    },
  },
];
