"""Tests for run_ci_checks.py."""

from run_ci_checks import (
    Check,
    run_check,
    run_checks,
)


def test_run_check_success():
    """Test running a successful check."""
    check = Check(name="Test Check", command=["echo", "hello"])
    result = run_check(check)
    assert result.check == check
    assert result.exit_code == 0
    assert "hello" in result.output


def test_run_check_failure():
    """Test running a failing check."""
    check = Check(name="Test Check", command=["false"])
    result = run_check(check)
    assert result.check == check
    assert result.exit_code != 0


def test_run_check_timeout():
    """Test check timeout handling."""
    check = Check(name="Test Check", command=["sleep", "2"])
    result = run_check(check, timeout=0.01)
    assert result.exit_code == 124
    assert "timed out" in result.output.lower()


def test_run_checks_success():
    """Test run_checks function with successful checks."""
    test_checks = [
        Check(name="Success Check 1", command=["echo", "success1"]),
        Check(name="Success Check 2", command=["echo", "success2"]),
    ]

    result = run_checks(
        test_checks,
        token="test-token",  # noqa: S106 - not a real password
        repo="test/repo",
        sha="abc123",
        report_to_github=False,
    )
    assert result == 0


def test_run_checks_with_failures():
    """Test run_checks function when checks fail."""
    test_checks = [
        Check(name="Failure Check 1", command=["false"]),
        Check(name="Failure Check 2", command=["false"]),
    ]

    result = run_checks(
        test_checks,
        token="test-token",  # noqa: S106 - not a real password
        repo="test/repo",
        sha="abc123",
        report_to_github=False,
    )
    assert result == 1
