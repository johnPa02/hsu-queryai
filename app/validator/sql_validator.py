"""SQL Validator — validate generated SQL for safety and correctness."""

import re
import structlog

logger = structlog.get_logger()

# Dangerous SQL patterns (block anything except SELECT)
BLOCKED_PATTERNS = [
    r"\b(INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE|CREATE|GRANT|REVOKE)\b",
    r"\b(EXECUTE|EXEC)\b",
    r";\s*(INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE|CREATE)",
]


class SQLValidator:
    """Validate SQL queries for safety and basic correctness."""

    def validate(self, sql: str) -> dict:
        """
        Validate a SQL query.
        Returns: {"valid": bool, "errors": list[str], "sanitized_sql": str}
        """
        errors = []
        sanitized = sql.strip()

        # Remove trailing semicolons for safety
        sanitized = sanitized.rstrip(";") + ";"

        # Check for blocked patterns
        for pattern in BLOCKED_PATTERNS:
            if re.search(pattern, sanitized, re.IGNORECASE):
                errors.append(f"Blocked SQL pattern detected: {pattern}")

        # Must start with SELECT or WITH (CTE)
        normalized = sanitized.strip().upper()
        if not (normalized.startswith("SELECT") or normalized.startswith("WITH")):
            errors.append("Query must start with SELECT or WITH")

        # Check for multiple statements (injection protection)
        # Split by semicolons, ignore empty parts
        parts = [p.strip() for p in sanitized.split(";") if p.strip()]
        if len(parts) > 1:
            # Allow UNION ALL which may look like multiple parts but isn't
            if not any(kw in sanitized.upper() for kw in ["UNION ALL", "UNION"]):
                errors.append("Multiple SQL statements not allowed")

        # Check for common issues
        if '""' in sanitized:
            errors.append("Empty double-quoted identifier detected")

        is_valid = len(errors) == 0

        if is_valid:
            logger.info("sql_validated", valid=True)
        else:
            logger.warning("sql_validation_failed", errors=errors)

        return {
            "valid": is_valid,
            "errors": errors,
            "sanitized_sql": sanitized,
        }
