import { describe, it, expect, beforeAll, vi } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router";
import i18n from "@/i18n";
import { AuthContext, type AuthContextValue } from "@/auth/context";
import { ApiError } from "@/auth/api-error";
import { RegisterScreen } from "./RegisterScreen";

/*
 * Register form (issue 03): success calls the auth action with the detected
 * timezone; a local password-mismatch shows inline without hitting the API; a
 * 422 surfaces per-field errors inline.
 */
function renderRegister(overrides: Partial<AuthContextValue> = {}) {
  const value: AuthContextValue = {
    status: "unauthed",
    user: null,
    login: vi.fn(),
    register: vi.fn().mockResolvedValue(undefined),
    logout: vi.fn(),
    ...overrides,
  };
  render(
    <AuthContext.Provider value={value}>
      <MemoryRouter>
        <RegisterScreen />
      </MemoryRouter>
    </AuthContext.Provider>,
  );
  return value;
}

function fill(username: string, password: string, confirm: string) {
  fireEvent.change(screen.getByLabelText("Username or email"), {
    target: { value: username },
  });
  fireEvent.change(screen.getByLabelText("Password"), {
    target: { value: password },
  });
  fireEvent.change(screen.getByLabelText("Confirm password"), {
    target: { value: confirm },
  });
}

describe("RegisterScreen", () => {
  beforeAll(async () => {
    await i18n.changeLanguage("en-US");
  });

  it("registers with username, password, and a detected timezone on success", async () => {
    const register = vi.fn().mockResolvedValue(undefined);
    renderRegister({ register });

    fill("alice", "secret123", "secret123");
    fireEvent.click(screen.getByRole("button", { name: "Create account" }));

    await waitFor(() =>
      expect(register).toHaveBeenCalledWith(
        expect.objectContaining({
          username: "alice",
          password: "secret123",
          timezone: expect.any(String),
        }),
      ),
    );
    const arg = register.mock.calls[0][0] as { timezone: string };
    expect(arg.timezone.length).toBeGreaterThan(0);
  });

  it("shows a password-mismatch error inline without calling the API", async () => {
    const register = vi.fn();
    renderRegister({ register });

    fill("alice", "secret123", "different");
    fireEvent.click(screen.getByRole("button", { name: "Create account" }));

    expect(
      await screen.findByText("Passwords do not match."),
    ).toBeInTheDocument();
    expect(register).not.toHaveBeenCalled();
  });

  it("surfaces per-field 422 errors inline", async () => {
    const register = vi.fn().mockRejectedValue(
      new ApiError({
        code: "validation_failed",
        message: "Validation failed",
        details: { username: ["has already been taken"] },
      }),
    );
    renderRegister({ register });

    fill("alice", "secret123", "secret123");
    fireEvent.click(screen.getByRole("button", { name: "Create account" }));

    expect(
      await screen.findByText("has already been taken"),
    ).toBeInTheDocument();
  });
});
