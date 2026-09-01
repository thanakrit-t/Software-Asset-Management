export type AppRole = "admin" | "user";

export interface Viewer {
  id: string;
  displayName: string;
  email: string;
  role: AppRole;
}

export interface AuthActionState {
  error?: string;
  fieldErrors?: {
    email?: string;
    password?: string;
  };
}

export const initialAuthActionState: AuthActionState = {};
