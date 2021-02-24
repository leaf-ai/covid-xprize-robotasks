import os
from unittest import TestCase
from unittest.mock import patch

from pandas import DataFrame

from judging.generate_predictions_local import generate_predictions, get_predictions_tasks

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
FIXTURES_PATH = os.path.join(ROOT_DIR, "fixtures")


class TestPrescriptionValidation(TestCase):

    @patch('subprocess.call')
    def test_empty_df(self, call_mock):
        df = DataFrame()
        generate_predictions(df, prediction_module='')
        call_mock.assert_not_called()

    @patch('subprocess.call')
    def test_generate_single_prediction(self, call_mock):
        df = get_predictions_tasks(os.path.join(FIXTURES_PATH, 'sample_predictions_task.csv'))
        self.assertEqual(1, len(df), "Should be a single prediction request")

        predict_module = 'test/predict.py'
        generate_predictions(df, predict_module)
        call_mock.assert_called_with([
            'python',
            predict_module,
            '--start_date', df.iloc[0].StartDate,
            '--end_date', df.iloc[0].EndDate,
            '--interventions_plan', df.iloc[0].IpFile,
            '--output_file', df.iloc[0].OutputFile
        ])
