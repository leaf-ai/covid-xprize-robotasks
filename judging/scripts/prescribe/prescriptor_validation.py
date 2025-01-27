"""
Validates generated prescriptions.

Valiation errors are written to stdout.

This duplicates functionality in the prescriptor validation script in the covid-xprize repo. It is copy-pasted here
to avoid tangling dependencies, but this could be cleaned up in future.
"""

# Copyright 2021 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

import argparse
import logging
import itertools
from typing import List

import numpy as np
import pandas as pd


ID_COLS = ['CountryName',
           'RegionName',
           'Date']
NPI_COLUMNS = ['C1_School closing',
               'C2_Workplace closing',
               'C3_Cancel public events',
               'C4_Restrictions on gatherings',
               'C5_Close public transport',
               'C6_Stay at home requirements',
               'C7_Restrictions on internal movement',
               'C8_International travel controls',
               'H1_Public information campaigns',
               'H2_Testing policy',
               'H3_Contact tracing',
               'H6_Facial Coverings']
PRESCRIPTION_INDEX_COL = "PrescriptionIndex"
COLUMNS = ID_COLS + NPI_COLUMNS + ["PrescriptionIndex"]
DATE = "Date"

IP_MAX_VALUES = {
    'C1_School closing': 3,
    'C2_Workplace closing': 3,
    'C3_Cancel public events': 2,
    'C4_Restrictions on gatherings': 4,
    'C5_Close public transport': 2,
    'C6_Stay at home requirements': 3,
    'C7_Restrictions on internal movement': 2,
    'C8_International travel controls': 4,
    'H1_Public information campaigns': 2,
    'H2_Testing policy': 3,
    'H3_Contact tracing': 2,
    'H6_Facial Coverings': 4
}

logging.basicConfig(
    format='%(asctime)s %(name)-20s %(levelname)-8s %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S'
)
LOGGER = logging.getLogger('prescriptor_validation')


def validate_submission(start_date: str,
                        end_date: str,
                        ip_file: str,
                        submission_file: str) -> List[str]:
    """
    Checks a prescription submission file is valid.
    Args:
        start_date: the submission start date as a string, format YYYY-MM-DDD
        end_date: the submission end date as a string, format YYYY-MM-DDD
        ip_file: path to a file-like object
        submission_file: path to a file-like object

    Returns: a list of string messages if errors were detected, an empty list otherwise

    """
    presc_df = pd.read_csv(submission_file,
                           parse_dates=['Date'],
                           encoding="ISO-8859-1",
                           dtype={"RegionName": str},
                           error_bad_lines=True)
    ip_df = pd.read_csv(ip_file,
                        parse_dates=['Date'],
                        encoding="ISO-8859-1",
                        dtype={"RegionName": str},
                        error_bad_lines=True)

    all_errors = []
    # Check we got the expected columns
    all_errors += _check_columns(set(COLUMNS), presc_df)
    if not all_errors:
        # For each individual prescription in the prescriptions file
        prescription_indexes = presc_df.PrescriptionIndex.unique()
        for i in prescription_indexes:
            i_presc_df = presc_df[presc_df.PrescriptionIndex == i].copy()
            # Columns are good, check we got prescriptions for each requested country / region
            all_errors += _check_geos(ip_df, i_presc_df)
            # Check the IP values
            all_errors += _check_prescription_values(i_presc_df)
            # Check the prediction dates are correct
            all_errors += _check_days(start_date, end_date, i_presc_df)

    return all_errors


def _check_columns(expected_columns, pred_df):
    errors = []
    # Make sure each column is present
    missing_columns = expected_columns - set(pred_df.columns)
    if missing_columns:
        errors.append(f"Missing columns: {missing_columns}")
        # Columns are not there, can't check anything more
        return errors

    # Make sure column Date contains dates
    date_column_type = pred_df[DATE].dtype
    if not np.issubdtype(date_column_type, np.datetime64):
        errors.append(f"Column {DATE} contains non date values: {date_column_type}")

    # Make sure each NPI columns contains numbers
    for npi_column in IP_MAX_VALUES.keys():
        npi_column_type = pred_df[npi_column].dtype
        if not np.issubdtype(npi_column_type, np.number):
            errors.append(f"Column {npi_column} contains non numerical values: {npi_column_type}")

    return errors


def _check_prescription_values(df):
    # For each IP column, check the values are valid
    errors = []
    for ip_name, ip_max_value in IP_MAX_VALUES.items():
        if df[ip_name].isnull().values.any():
            errors.append(f"Column {ip_name} contains NaN values")
        if df[ip_name].min() < 0:
            errors.append(f"Column {ip_name} contains negative values")
        if df[ip_name].max() > ip_max_value:
            errors.append(f"Column {ip_name} contains values higher than max possible value")
    return errors


def _check_geos(ip_df, pred_df):
    errors = []
    _add_geoid_column(ip_df)
    _add_geoid_column(pred_df)
    requested_geo_ids = set(ip_df.GeoID.unique())
    actual_geo_ids = set(pred_df.GeoID.unique())
    # Check if any missing
    # Additional geos are OK, but predictions should at least include requested ones
    missing_geos = requested_geo_ids - actual_geo_ids
    if missing_geos:
        errors.append(f"Missing countries / regions: {missing_geos}")
    return errors


def _add_geoid_column(df):
    # Add GeoID column that combines CountryName and RegionName for easier manipulation of data
    # np.where usage: if A then B else C
    df["GeoID"] = np.where(df["RegionName"].isnull(),
                           df["CountryName"],
                           df["CountryName"] + ' / ' + df["RegionName"])


def _check_days(start_date, end_date, df):
    errors = []
    _add_geoid_column(df)
    # Sort by geo and date
    df.sort_values(by=["GeoID", "Date"], inplace=True)
    # Convert the dates
    start_date = pd.to_datetime(start_date, format='%Y-%m-%d')
    end_date = pd.to_datetime(end_date, format='%Y-%m-%d')
    num_days = (end_date - start_date).days + 1
    expected_dates = [start_date + pd.offsets.Day(i) for i in range(num_days)]
    # Get the geo names
    geo_ids = list(df.GeoID.unique())
    for geo_id in geo_ids:
        pred_dates = df[df.GeoID == geo_id].Date
        for expected_date, pred_date in itertools.zip_longest(expected_dates, pred_dates, fillvalue=None):
            if not expected_date == pred_date:
                errors.append(f"{geo_id}: Expected prediction for date "
                              f"{expected_date.strftime('%Y-%m-%d') if expected_date is not None else None}"
                              f" but got {pred_date.strftime('%Y-%m-%d') if pred_date is not None else None}")
    return errors


def do_main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--start_date",
                        dest="start_date",
                        type=str,
                        required=False,
                        default="2020-12-22",
                        help="First date of prescriptions"
                             "Format YYYY-MM-DD. For example 2021-02-15")
    parser.add_argument("-e", "--end_date",
                        dest="end_date",
                        type=str,
                        required=False,
                        default="2021-06-19",
                        help="Last date of prescriptions"
                             "Format YYYY-MM-DD. For example 2021-05-15")
    parser.add_argument("-ip", "--interventions_plan",
                        dest="ip_file",
                        type=str,
                        required=True,
                        help="The path to an intervention plan .csv file")
    parser.add_argument("-f", "--submission_file",
                        dest="submission_file",
                        type=str,
                        required=True,
                        help="Path to the filename containing the submission (prescriptions) to be validated.")
    args = parser.parse_args()

    submission_file = args.submission_file
    start_date = args.start_date
    end_date = args.end_date
    ip_file = args.ip_file
    LOGGER.info(f"Validating submission file {submission_file} "
                f"start date {start_date} end date {end_date} intervention plan {ip_file}")

    errors = validate_submission(start_date, end_date, ip_file, submission_file)
    if not errors:
        LOGGER.info(f'{submission_file} submission passes validation')
    else:
        LOGGER.warning(f'Submission {submission_file} has errors: ')
        LOGGER.warning('\n'.join(errors))

    LOGGER.info(f"Done!")


if __name__ == '__main__':
    do_main()
