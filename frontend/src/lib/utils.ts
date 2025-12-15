import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export type WithElementRef<
  T,
  K extends keyof HTMLElementTagNameMap = "div",
> = T & {
  ref?: HTMLElementTagNameMap[K] | null;
};

export type WithoutChildrenOrChild<T> = T & {
  children?: never;
  child?: never;
};

export type WithoutChildren<T> = T & {
  children?: never;
};

export type WithoutChild<T> = T & {
  child?: never;
};
