import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router";
import i18n from "@/i18n";
import { AuthContext, type AuthContextValue } from "@/auth/context";
import { ApiError } from "@/auth/api-error";
import { LoginScreen } from "./LoginScreen";

/*
 * Login form (issue 03): success calls the auth action; an API error envelope is
 * surfaced inline; the submit button shows a spinner + disables while in flight.
 */
function renderLogin(overrides: Partial<AuthContextValue> = {}) {
  const value: AuthContextValue = {
    status: "unauthed",
    user: null,
    login: vi.fn().mockResolvedValue(undefined),
    register: vi.fn(),
    logout: vi.fn(),
    ...overrides,
  };
  render(
    <AuthContext.Provider value={value}>
      <MemoryRouter>
        <LoginScreen />
      </MemoryRouter>
    </AuthContext.Provider>,
  );
  return value;
}

function fillCredentials() {
  fireEvent.change(screen.getByLabelText("Username or email"), {
    target: { value: "alice" },
  });
  fireEvent.change(screen.getByLabelText("Password"), {
    target: { value: "secret123" },
  });
}

describe("LoginScreen", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("submits the credentials to the auth action on success", async () => {
    const login = vi.fn().mockResolvedValue(undefined);
    renderLogin({ login });

    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));

    await waitFor(() =>
      expect(login).toHaveBeenCalledWith({
        username: "alice",
        password: "secret123",
      }),
    );
  });

  it("surfaces an API validation error inline", async () => {
    const login = vi
      .fn()
      .mockRejectedValue(
        new ApiError({
          code: "invalid_credentials",
          message: "Invalid username or password.",
        }),
      );
    renderLogin({ login });

    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));

    expect(
      await screen.findByText("Invalid username or password."),
    ).toBeInTheDocument();
    expect(screen.getByRole("alert")).toBeInTheDocument();
  });

  it("disables the button and shows a spinner label while submitting", async () => {
    let resolveLogin: () => void = () => {};
    const login = vi.fn(
      () =>
        new Promise<void>((resolve) => {
          resolveLogin = resolve;
        }),
    );
    renderLogin({ login });

    fillCredentials();
    fireEvent.click(screen.getByRole("button", { name: "Sign in" }));

    const submitting = await screen.findByRole("button", {
      name: "Signing in…",
    });
    expect(submitting).toBeDisabled();

    resolveLogin();
    await waitFor(() =>
      expect(
        screen.getByRole("button", { name: "Sign in" }),
      ).not.toBeDisabled(),
    );
  });
});
