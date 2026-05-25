import asyncio
import logging
from typing import List, Dict, Any
import pandas as pd
from sklearn.ensemble import IsolationForest

logger = logging.getLogger("app.ai.scanner")

def _run_isolation_forest(attendance_records: List[Dict[str, Any]], contamination: float) -> List[Dict[str, Any]]:
    """Synchronous CPU-bound helper function to compute absentee anomalies."""
    try:
        if not attendance_records:
            return []

        df = pd.DataFrame(attendance_records)
        
        required_cols = {'student_id', 'status', 'day_of_week'}
        if not required_cols.issubset(df.columns):
            logger.error("Missing required columns in attendance records. Required: %s", required_cols)
            return []

        absences = df[df['status'] == 'Absent']
        if absences.empty:
            return []
            
        profile = absences.groupby('student_id').size().reset_index(name='total_absences')
        day_absences = pd.crosstab(absences['student_id'], absences['day_of_week']).reset_index()
        profile = pd.merge(profile, day_absences, on='student_id', how='left').fillna(0)
        
        features = profile.drop(columns=['student_id'])
        
        model = IsolationForest(n_estimators=100, contamination=contamination, random_state=42)
        profile['anomaly_score'] = model.fit_predict(features)
        
        flagged = profile[profile['anomaly_score'] == -1].copy()
        flagged = flagged.sort_values(by='total_absences', ascending=False)
        flagged = flagged.drop(columns=['anomaly_score'])
        
        return flagged.to_dict(orient='records')
        
    except Exception as e:
        logger.error("Error in IsolationForest absentee scan: %s", e, exc_info=True)
        return []

async def run_absentee_scan(attendance_records: List[Dict[str, Any]], contamination: float = 0.10) -> List[Dict[str, Any]]:
    """
    Asynchronously runs the absentee anomaly detection without blocking the FastAPI event loop.
    
    Args:
        attendance_records: A list of dictionaries containing 'student_id', 'status', and 'day_of_week'.
        contamination: The expected proportion of outliers (0 to 0.5).
        
    Returns:
        A list of dictionaries representing the flagged, at-risk students.
    """
    try:
        # Offload the heavy synchronous pandas/scikit-learn logic to a background thread
        flagged_students = await asyncio.to_thread(_run_isolation_forest, attendance_records, contamination)
        if flagged_students:
            logger.info("Found %d at-risk students during absentee scan.", len(flagged_students))
        else:
            logger.info("No at-risk students detected during absentee scan.")
        return flagged_students
    except Exception as e:
        logger.error("Failed to run async absentee scan wrapper: %s", e)
        return []