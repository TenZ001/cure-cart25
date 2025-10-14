/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          cyan: '#06b6d4',
          light: '#e0f2fe',
          blue: '#38bdf8',
          dark: '#0e7490',
          primary: '#0f172a',
          sky: '#f0f9ff',
        },
      },
    },
  },
  plugins: [],
};


