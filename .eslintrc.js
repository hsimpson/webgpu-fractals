module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2022,
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  root: true,
  env: {
    node: true,
    es6: true,
  },
  rules: {
    '@typescript-eslint/ban-ts-comment': 'warn',
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/no-explicit-any': 'warn', // FIXME: turn this into a warning some day
    '@typescript-eslint/no-shadow': 'error',
    '@typescript-eslint/no-unused-vars': ['warn', { varsIgnorePattern: '^_', argsIgnorePattern: '^_' }],
    '@typescript-eslint/promise-function-async': 'error',
    '@typescript-eslint/require-await': 'error',
    'array-callback-return': 'error',
    'no-console': 'warn',
    'no-unused-vars': 'off',
    'no-warning-comments': 'warn',
    'object-shorthand': ['warn', 'always'],
    curly: 'warn',
    eqeqeq: 'warn',
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
};
