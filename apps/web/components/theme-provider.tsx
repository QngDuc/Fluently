"use client";

import {
  createContext,
  type Dispatch,
  type SetStateAction,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

const ThemeContext = createContext<{
  theme: string;
  setTheme: Dispatch<SetStateAction<string>>;
}>({
  theme: "light",
  setTheme: () => undefined,
});

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState("light");

  useEffect(() => {
    const storedTheme = window.localStorage.getItem("theme") ?? "light";
    setTheme(storedTheme);
    document.documentElement.classList.toggle("dark", storedTheme === "dark");
  }, []);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", theme === "dark");
    window.localStorage.setItem("theme", theme);
  }, [theme]);

  const value = useMemo(() => ({ theme, setTheme }), [theme]);

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
}

export function useTheme() {
  return useContext(ThemeContext);
}
