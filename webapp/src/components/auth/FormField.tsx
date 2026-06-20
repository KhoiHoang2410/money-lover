import { useId } from "react";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";

interface FormFieldProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  /** Inline error message (per-field, from the API envelope or local checks). */
  error?: string;
}

// Labelled text field with inline error wiring (aria-invalid + aria-describedby)
// for the auth forms. Errors render in danger red under the pill input.
export function FormField({ label, error, className, ...props }: FormFieldProps) {
  const id = useId();
  const errorId = `${id}-error`;
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-sm font-medium text-foreground">
        {label}
      </label>
      <Input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? errorId : undefined}
        className={cn(error && "border-destructive", className)}
        {...props}
      />
      {error && (
        <p id={errorId} role="alert" className="text-sm text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
