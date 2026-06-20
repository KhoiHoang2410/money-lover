/// <reference types="vite/client" />

declare module "*.yaml" {
  const value: Record<string, unknown>;
  export default value;
}

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
