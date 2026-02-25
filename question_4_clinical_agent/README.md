# GenAI Clinical Data Assistant

**Python Coding Assessment - Question 4**

A Generative AI assistant that translates natural language questions into structured Pandas queries for clinical trial adverse events data.
---

## Quick Start

### 1. Setup Virtual Environment

```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Run the Test Suite

```bash
# Run the 3 required test cases
python test_agent.py
```

### 3. Try the Jupyter Notebook

```bash
# Install Jupyter (if needed)
pip install jupyter matplotlib seaborn

# Open the notebook
jupyter notebook genai_clinical_assistant.ipynb
```

---

## Files in This Repository

```
genai-clincal-assistant/
├── adae.csv                           # Adverse events dataset (pharmaversesdtm::ae)
├── clinical_data_agent.py             # Main implementation (with OpenAI & Mock mode)
├── test_agent.py                      # Test script with 3 required examples
├── genai_clinical_assistant.ipynb     # Interactive Jupyter notebook demo
├── requirements.txt                   # Python dependencies
├── README.md                          # This file
├── .gitignore                         # Git ignore rules
```

---

## How It Works

### Architecture

```
User Question: "Give me subjects with moderate severity"
         ↓
    LLM Parser (GPT-4 or Mock Mode)
         ↓
Structured JSON: {"target_column": "AESEV", "filter_value": "MODERATE"}
         ↓
    Pandas Filter: df[df['AESEV'] == 'MODERATE']
         ↓
Results: (136 subjects, ['01-701-1023', '01-701-1047', ...], DataFrame)
```

### Key Features

- **Natural Language Understanding** - Ask in plain English
- **Intelligent Mapping** - No hard-coded rules, uses LLM
- **Two Modes**:
  - **Mock Mode** (default) - Rule-based, no API key needed
  - **OpenAI Mode** - Real LLM for complex queries
---

## Dataset Schema

The assistant works with CDISC SDTM adverse events data (`adae.csv`):

| Column | Description | Example Values |
|--------|-------------|----------------|
| **USUBJID** | Unique Subject Identifier | 01-701-1015 |
| **AETERM** | Adverse Event Term | ERYTHEMA, DIARRHOEA, FATIGUE |
| **AESEV** | Severity | MILD, MODERATE, SEVERE |
| **AESOC** | System Organ Class | CARDIAC DISORDERS, SKIN AND SUBCUTANEOUS TISSUE DISORDERS |
| **AEREL** | Relationship to Drug | PROBABLE, POSSIBLE, REMOTE, NONE |
| **AEOUT** | Outcome | RECOVERED/RESOLVED, NOT RECOVERED/NOT RESOLVED |

---

## The 3 Required Test Cases

### Test Case 1: Moderate Severity
```python
Question: "Give me the subjects who had Adverse events of Moderate severity"
Result: 136 unique subjects, 378 events
Maps to: AESEV = 'MODERATE'
```

### Test Case 2: Cardiac Disorders
```python
Question: "Which subjects experienced cardiac disorders?"
Result: 44 unique subjects, 91 events
Maps to: AESOC = 'CARDIAC DISORDERS'
```

### Test Case 3: Erythema
```python
Question: "Show me patients with erythema"
Result: 38 unique subjects, 59 events
Maps to: AETERM = 'ERYTHEMA'
```

---

## Usage Examples

### Basic Usage (Mock Mode)

```python
from clinical_data_agent import ClinicalTrialDataAgent

# Initialize agent (no API key needed)
agent = ClinicalTrialDataAgent(
    data_path='adae.csv',
    use_mock_llm=True
)

# Ask a question
count, subject_ids, df = agent.query(
    "Give me subjects with moderate severity"
)

print(f"Found {count} subjects: {subject_ids[:5]}...")
```

### With OpenAI API

```python
import os
os.environ['OPENAI_API_KEY'] = 'your-key-here'

# Initialize with real LLM
agent = ClinicalTrialDataAgent(
    data_path='adae.csv',
    use_mock_llm=False
)

# Now uses GPT-4 for intelligent parsing
agent.display_results("Which subjects had gastrointestinal issues?")
```

### Example Questions the Agent Understands

```python
# Severity queries
"subjects with moderate severity"
"Who had severe adverse events?"
"Show me mild intensity reactions"

# Body system queries
"cardiac disorders"
"gastrointestinal adverse events"
"skin reactions"
"nervous system issues"

# Specific conditions
"patients with erythema"
"subjects with diarrhea"
"who had fatigue?"

# Other attributes
"serious adverse events"
"events related to treatment"
"patients who recovered"
```

---

## Implementation Details

### ClinicalTrialDataAgent Class

Located in `clinical_data_agent.py`:

```python
class ClinicalTrialDataAgent:
    def __init__(self, data_path: str, use_mock_llm: bool = False)
    def _call_llm(self, question: str) -> Dict[str, str]
    def query(self, question: str) -> Tuple[int, List[str], pd.DataFrame]
    def display_results(self, question: str) -> None
```

**Key Methods:**
- `_call_llm()` - Parses question to structured JSON
- `query()` - Executes filter and returns (count, IDs, DataFrame)
- `display_results()` - User-friendly formatted output

### Structured Output

Every query returns JSON:
```json
{
  "target_column": "AESEV",
  "filter_value": "MODERATE"
}
```

### Mock Mode Intelligence

When `use_mock_llm=True`, uses rule-based parsing:
- Keyword matching: "severity" → AESEV
- Synonym mapping: "cardiac" → CARDIAC DISORDERS
- Pattern recognition: "moderate" → MODERATE
- Smart defaults

---

## Dependencies

```
pandas>=2.0.0          # Data manipulation
openai>=1.0.0          # OpenAI API (optional)
langchain>=0.1.0       # LangChain framework (optional)
langchain-openai       # LangChain OpenAI integration (optional)
python-dotenv          # Environment variables (optional)
```

**Minimum (Mock Mode):** Only pandas required!

---

## Running Tests

### Run All Test Cases
```bash
python test_agent.py
```

**Expected Output:**
```
==========================================================================================
🧪 CLINICAL DATA AGENT - TEST SUITE
==========================================================================================

Initializing agent with adae.csv...
✅ Agent initialized successfully!

📝 Running 3 test cases...

==========================================================================================
TEST CASE #1
==========================================================================================
...
✅ Test 1: PASS - 136 subjects, 378 records
✅ Test 2: PASS - 44 subjects, 91 records
✅ Test 3: PASS - 38 subjects, 59 records

==========================================================================================
Overall: 3/3 tests passed
==========================================================================================
```

---

## Jupyter Notebook

The notebook `genai_clinical_assistant.ipynb` provides:

- Complete interactive demonstration
- All 3 test cases with visualizations
- Dataset exploration
- Architecture explanation
- Additional query examples
- Parsing demonstration

**Run it:**
```bash
source venv/bin/activate
jupyter notebook genai_clinical_assistant.ipynb
```

---

## Implementation Features

The `clinical_data_agent.py` file provides:

- **Direct OpenAI API integration** - Use GPT-4 for real LLM queries
- **Mock Mode** - Rule-based parsing for testing without API key
---


## Troubleshooting

**Import errors?**
```bash
source venv/bin/activate
pip install -r requirements.txt
```

**No Python?**
```bash
# Install Python 3.8+
sudo apt install python3 python3-venv python3-pip
```

**API errors (if using OpenAI)?**
```bash
# Set your API key
export OPENAI_API_KEY='your-key-here'

# Or in Python:
import os
os.environ['OPENAI_API_KEY'] = 'your-key-here'
```

**Mock mode not working?**
- Ensure `use_mock_llm=True` in initialization
- Check that adae.csv exists and is readable

---

## Next Steps

1. **Test it**: Run `python test_agent.py`
2. **Explore**: Open the Jupyter notebook
3. **Extend**: Add more query types in the mock parser
4. **Deploy**: Switch to OpenAI API for production
5. **Integrate**: Import the agent into your applications

---

## License

MIT License - Feel free to use and modify

---
