"""
GenAI Clinical Data Assistant
Translates natural language questions into structured Pandas queries for clinical trial data.
"""

import pandas as pd
import json
from typing import Dict, List, Tuple
import os


class ClinicalTrialDataAgent:
    """
    Agent that uses LLM to parse natural language questions about clinical trial data
    and executes Pandas queries to return relevant subject information.
    """

    def __init__(self, data_path: str, use_mock_llm: bool = False):
        """
        Initialize the agent with the clinical trial data.

        Args:
            data_path: Path to the adae.csv file
            use_mock_llm: If True, use mock LLM responses instead of real API calls
        """
        self.df = pd.read_csv(data_path)
        self.use_mock_llm = use_mock_llm

        # Schema definition for the LLM to understand the dataset
        self.schema_definition = """
        Clinical Trial Adverse Events Dataset Schema:

        Key Columns:
        - USUBJID: Unique Subject Identifier (used to count unique subjects)
        - AETERM: Adverse Event Term (the name/description of the adverse event, e.g., "ERYTHEMA", "DIARRHOEA", "FATIGUE")
        - AESEV: Severity of the Adverse Event (values: "MILD", "MODERATE", "SEVERE")
        - AESOC: System Organ Class (body system affected, e.g., "CARDIAC DISORDERS", "SKIN AND SUBCUTANEOUS TISSUE DISORDERS", "GASTROINTESTINAL DISORDERS")
        - AEBODSYS: Body System (similar to AESOC, the organ system classification)
        - AESER: Serious Event Flag (Y/N)
        - AEREL: Relationship to Study Drug (e.g., "PROBABLE", "POSSIBLE", "REMOTE", "NONE")
        - AEOUT: Outcome (e.g., "RECOVERED/RESOLVED", "NOT RECOVERED/NOT RESOLVED")
        - AESTDTC: Start Date of Adverse Event
        - AEENDTC: End Date of Adverse Event

        Common Question Mappings:
        - Questions about "severity", "intensity", "how severe" → Use AESEV column
        - Questions about specific conditions, symptoms, or event names (e.g., "headache", "diarrhea", "erythema") → Use AETERM column
        - Questions about body systems, organ classes (e.g., "cardiac", "skin", "gastrointestinal") → Use AESOC or AEBODSYS column
        - Questions about serious events → Use AESER column
        - Questions about relationship/relatedness to drug → Use AEREL column
        - Questions about outcomes, resolution → Use AEOUT column
        """

    def _call_llm(self, question: str) -> Dict[str, str]:
        """
        Call LLM to parse the question into structured output.

        Args:
            question: Natural language question from user

        Returns:
            Dictionary with 'target_column' and 'filter_value'
        """
        if self.use_mock_llm:
            return self._mock_llm_response(question)

        # Real LLM implementation using OpenAI
        try:
            from openai import OpenAI

            client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

            prompt = f"""
{self.schema_definition}

Task: Parse the following question and return ONLY a JSON object with two fields:
1. "target_column": The column name to filter on (must be exactly one of: AETERM, AESEV, AESOC, AEBODSYS, AESER, AEREL, AEOUT)
2. "filter_value": The exact value to search for (use uppercase for consistency)

Question: {question}

Important:
- For severity questions: AESEV can be "MILD", "MODERATE", or "SEVERE"
- For condition/event names: Use AETERM and extract the medical term
- For body systems: Use AESOC or AEBODSYS
- Return ONLY valid JSON, no additional text

Example response format:
{{"target_column": "AESEV", "filter_value": "MODERATE"}}
"""

            response = client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "You are a clinical data parsing assistant. Return only valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0
            )

            result = json.loads(response.choices[0].message.content)
            return result

        except ImportError:
            print("OpenAI library not installed. Using mock LLM.")
            return self._mock_llm_response(question)
        except Exception as e:
            print(f"Error calling LLM: {e}. Using mock response.")
            return self._mock_llm_response(question)

    def _mock_llm_response(self, question: str) -> Dict[str, str]:
        """
        Mock LLM response for testing without API key.
        Uses simple rule-based parsing.

        Args:
            question: Natural language question

        Returns:
            Dictionary with 'target_column' and 'filter_value'
        """
        question_lower = question.lower()

        # Severity/Intensity mapping
        if any(word in question_lower for word in ['severity', 'severe', 'intensity', 'intense']):
            if 'mild' in question_lower:
                return {"target_column": "AESEV", "filter_value": "MILD"}
            elif 'moderate' in question_lower:
                return {"target_column": "AESEV", "filter_value": "MODERATE"}
            elif 'severe' in question_lower:
                return {"target_column": "AESEV", "filter_value": "SEVERE"}

        # Body system mapping
        if any(word in question_lower for word in ['cardiac', 'heart', 'cardiovascular']):
            return {"target_column": "AESOC", "filter_value": "CARDIAC DISORDERS"}
        elif any(word in question_lower for word in ['skin', 'dermal', 'dermatologic']):
            return {"target_column": "AESOC", "filter_value": "SKIN AND SUBCUTANEOUS TISSUE DISORDERS"}
        elif any(word in question_lower for word in ['gastrointestinal', 'digestive', 'gi', 'stomach']):
            return {"target_column": "AESOC", "filter_value": "GASTROINTESTINAL DISORDERS"}
        elif any(word in question_lower for word in ['infection', 'infectious']):
            return {"target_column": "AESOC", "filter_value": "INFECTIONS AND INFESTATIONS"}
        elif any(word in question_lower for word in ['general disorder', 'administration site']):
            return {"target_column": "AESOC", "filter_value": "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS"}

        # Specific condition mapping (AETERM)
        conditions = {
            'erythema': 'ERYTHEMA',
            'diarrhea': 'DIARRHOEA',
            'diarrhoea': 'DIARRHOEA',
            'fatigue': 'FATIGUE',
            'pruritus': 'APPLICATION SITE PRURITUS',
            'itching': 'APPLICATION SITE PRURITUS',
            'headache': 'HEADACHE',
            'nausea': 'NAUSEA',
            'hiatus hernia': 'HIATUS HERNIA',
            'bundle branch block': 'BUNDLE BRANCH BLOCK LEFT',
            'respiratory infection': 'UPPER RESPIRATORY TRACT INFECTION',
        }

        for condition_key, condition_value in conditions.items():
            if condition_key in question_lower:
                return {"target_column": "AETERM", "filter_value": condition_value}

        # Serious event mapping
        if 'serious' in question_lower:
            value = 'Y' if 'yes' in question_lower or 'serious' in question_lower else 'N'
            return {"target_column": "AESER", "filter_value": value}

        # Relationship mapping
        if 'relationship' in question_lower or 'related' in question_lower:
            if 'probable' in question_lower:
                return {"target_column": "AEREL", "filter_value": "PROBABLE"}
            elif 'possible' in question_lower:
                return {"target_column": "AEREL", "filter_value": "POSSIBLE"}
            elif 'remote' in question_lower:
                return {"target_column": "AEREL", "filter_value": "REMOTE"}
            elif 'none' in question_lower:
                return {"target_column": "AEREL", "filter_value": "NONE"}

        # Outcome mapping
        if 'outcome' in question_lower or 'resolved' in question_lower or 'recovered' in question_lower:
            if 'not' in question_lower:
                return {"target_column": "AEOUT", "filter_value": "NOT RECOVERED/NOT RESOLVED"}
            else:
                return {"target_column": "AEOUT", "filter_value": "RECOVERED/RESOLVED"}

        # Default fallback
        return {"target_column": "AESEV", "filter_value": "MILD"}

    def query(self, question: str) -> Tuple[int, List[str], pd.DataFrame]:
        """
        Process a natural language question and return filtered results.

        Args:
            question: Natural language question about the data

        Returns:
            Tuple of:
                - count: Number of unique subjects matching the criteria
                - subject_ids: List of unique subject IDs
                - filtered_df: DataFrame with all matching records
        """
        # Parse question using LLM
        llm_output = self._call_llm(question)

        target_column = llm_output['target_column']
        filter_value = llm_output['filter_value']

        print(f"\nParsed Query:")
        print(f"   Column: {target_column}")
        print(f"   Value: {filter_value}")

        # Execute Pandas filter
        filtered_df = self.df[
            self.df[target_column].str.upper() == filter_value.upper()
        ].copy()

        # Extract unique subjects
        unique_subjects = filtered_df['USUBJID'].unique().tolist()
        count = len(unique_subjects)

        return count, unique_subjects, filtered_df

    def display_results(self, question: str) -> None:
        """
        Query and display results in a user-friendly format.

        Args:
            question: Natural language question about the data
        """
        print(f"\n{'='*80}")
        print(f"Question: {question}")
        print(f"{'='*80}")

        count, subject_ids, filtered_df = self.query(question)

        print(f"\nResults:")
        print(f"   Total matching records: {len(filtered_df)}")
        print(f"   Unique subjects: {count}")
        print(f"\n👥 Subject IDs:")
        for idx, subject_id in enumerate(subject_ids, 1):
            print(f"   {idx}. {subject_id}")

        if len(filtered_df) > 0:
            print(f"\nSample Records (first 5):")
            print(filtered_df[['USUBJID', 'AETERM', 'AESEV', 'AESOC']].head().to_string(index=False))

        print(f"\n{'='*80}\n")


def main():
    """
    Test script demonstrating the ClinicalTrialDataAgent with example queries.
    """
    # Initialize agent with mock LLM (set to False to use real OpenAI API)
    agent = ClinicalTrialDataAgent(
        data_path='adae.csv',
        use_mock_llm=True  # Set to False if you have OpenAI API key
    )

    print("\n" + "="*80)
    print("GenAI Clinical Data Assistant - Test Suite")
    print("="*80)

    # Test Query 1: Severity-based question
    test_questions = [
        "Give me the subjects who had Adverse events of Moderate severity",
        "Which subjects experienced cardiac disorders?",
        "Show me patients with erythema"
    ]

    for question in test_questions:
        agent.display_results(question)


if __name__ == "__main__":
    main()
