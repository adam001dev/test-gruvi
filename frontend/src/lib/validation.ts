export interface ValidationResult {
  valid: boolean;
  error?: string;
}

export function validateDateRange(
  startDate?: string,
  endDate?: string,
): ValidationResult {
  if (!startDate && !endDate) {
    return { valid: true };
  }

  if (startDate && !endDate) {
    return { valid: true };
  }

  if (!startDate && endDate) {
    return { valid: true };
  }

  if (startDate && endDate) {
    const start = new Date(startDate);
    const end = new Date(endDate);

    if (isNaN(start.getTime())) {
      return { valid: false, error: "Invalid start date format" };
    }

    if (isNaN(end.getTime())) {
      return { valid: false, error: "Invalid end date format" };
    }

    if (start > end) {
      return {
        valid: false,
        error: "Start date must be less than or equal to end date",
      };
    }

    return { valid: true };
  }

  return { valid: true };
}

export function validateDateFormat(date: string): boolean {
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  if (!dateRegex.test(date)) {
    return false;
  }

  const d = new Date(date);
  return !isNaN(d.getTime()) && d.toISOString().startsWith(date);
}
