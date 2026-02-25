"""
Simple test script for the Clinical Trial Data Agent
Runs example queries and validates results
"""

from question_4_clinical_agent.clinical_data_agent import ClinicalTrialDataAgent
import sys


def run_basic_tests():
    """Run basic test suite with 3 example queries."""

    print("\n" + "=" * 90)
    print("CLINICAL DATA AGENT - TEST SUITE")
    print("=" * 90)

    # Initialize agent with mock LLM
    print("\nInitializing agent with adae.csv...")
    agent = ClinicalTrialDataAgent(data_path="adae.csv", use_mock_llm=True)
    print("Agent initialized successfully!")

    # Define test queries
    test_cases = [
        {
            "question": "Give me the subjects who had Adverse events of Moderate severity",
            "expected_column": "AESEV",
            "expected_value": "MODERATE",
        },
        {
            "question": "Which subjects experienced cardiac disorders?",
            "expected_column": "AESOC",
            "expected_value": "CARDIAC DISORDERS",
        },
        {
            "question": "Show me patients with erythema",
            "expected_column": "AETERM",
            "expected_value": "ERYTHEMA",
        },
    ]

    print(f"\nRunning {len(test_cases)} test cases...\n")

    # Run each test
    results = []
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{'='*90}")
        print(f"TEST CASE #{i}")
        print(f"{'='*90}")

        question = test_case["question"]

        # Execute query
        agent.display_results(question)

        # Verify results programmatically
        count, subject_ids, filtered_df = agent.query(question)

        test_result = {
            "test_number": i,
            "question": question,
            "passed": count > 0,
            "unique_subjects": count,
            "total_records": len(filtered_df),
        }

        results.append(test_result)

    # Print summary
    print("\n" + "=" * 90)
    print("TEST SUMMARY")
    print("=" * 90)

    total_tests = len(results)
    passed_tests = sum(1 for r in results if r["passed"])

    for result in results:
        status = "PASS" if result["passed"] else "FAIL"
        print(f"\nTest {result['test_number']}: {status}")
        print(f"  Question: {result['question']}")
        print(
            f"  Results: {result['unique_subjects']} subjects, {result['total_records']} records"
        )

    print(f"\n{'='*90}")
    print(f"Overall: {passed_tests}/{total_tests} tests passed")
    print(f"{'='*90}\n")

    return passed_tests == total_tests


def run_advanced_tests():
    """Run additional test cases for comprehensive validation."""

    print("\n" + "=" * 90)
    print("ADVANCED TEST SUITE")
    print("=" * 90)

    agent = ClinicalTrialDataAgent(data_path="adae.csv", use_mock_llm=True)

    advanced_queries = [
        "Who had mild severity events?",
        "Show me skin disorders",
        "Which subjects had gastrointestinal adverse events?",
        "List patients with fatigue",
    ]

    for i, question in enumerate(advanced_queries, 1):
        print(f"\n{'#'*90}")
        print(f"# ADVANCED TEST {i}")
        print(f"{'#'*90}")
        agent.display_results(question)


if __name__ == "__main__":
    # Run basic tests
    success = run_basic_tests()

    # Optionally run advanced tests
    if "--advanced" in sys.argv or "-a" in sys.argv:
        run_advanced_tests()

    # Exit with appropriate code
    sys.exit(0 if success else 1)
