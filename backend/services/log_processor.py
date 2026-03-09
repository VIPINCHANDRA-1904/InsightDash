import pandas as pd
import json
import os

def process_log_file(file_path: str):
    """
    Reads a log file or structured dataset (CSV/JSON/Log), parses it,
    and returns a summary using pandas.
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError("File not found.")

    # Try detecting the file format and read it using pandas
    try:
        if file_path.endswith('.csv'):
            df = pd.read_csv(file_path)
        elif file_path.endswith('.json'):
            df = pd.read_json(file_path)
        else:
            # Fallback for generic log files, assuming space/tab delimited or raw text
            # For simplicity in this lightweight tool, we read as csv with a separator guess
            try:
                df = pd.read_csv(file_path, sep=None, engine='python')
            except Exception:
                # If all else fails, read lines as a single column 'log_line'
                df = pd.read_csv(file_path, sep='\t', names=['log_line'], on_bad_lines='skip')
    except Exception as e:
        raise ValueError(f"Failed to parse the file: {str(e)}")
        
    total_rows = int(df.shape[0])
    total_columns = int(df.shape[1])
    
    # Columns info (dtype and missing values)
    columns_info = {}
    for col in df.columns:
        columns_info[str(col)] = {
            "type": str(df[col].dtype),
            "missing": int(df[col].isnull().sum())
        }
        
    # Summary stats for numerical columns
    numeric_df = df.select_dtypes(include=['number'])
    if not numeric_df.empty:
        summary_stats = numeric_df.describe().to_dict()
    else:
        summary_stats = {}
        
    # Categorical summary (top 5 frequencies for objects)
    categorical_df = df.select_dtypes(include=['object', 'category'])
    # Need to handle potential non-string column names
    for col in categorical_df.columns:
        col_str = str(col)
        if col_str not in summary_stats:
            summary_stats[col_str] = {}
        
        # Count and convert to normal dict securely
        counts = categorical_df[col].value_counts().head(5).to_dict()
        top_values = {str(k): int(v) for k, v in counts.items()}
        summary_stats[col_str]["top_values"] = top_values

    return {
        "total_rows": total_rows,
        "total_columns": total_columns,
        "columns_info": columns_info,
        "summary_stats": summary_stats
    }
