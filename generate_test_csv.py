import sys
import time
import random
import pandas as pd

from shapely.geometry import Polygon, Point


class GenerateTestCSV:
    MOSCOW_POLY = Polygon([(55.968114, 37.490135), 
                           (55.719427, 37.124899),
                           (55.434259, 37.699147),
                           (55.726489, 37.655277)])
    MCC_LIST = ['4812', '5912', '5399', '5699', '7991', '5712', '5732', '4900', '5211', '5815', '5719', '7996', '7394', '5541', '5331', '5411', '7399', '7011', '5943', '4111', '5300', '5310', '5942', '5651', '5309', '8999', '7922', '5946', '9311', '5499', '3102', '9402', '5200', '5977', '8220', '5311', '8099', '5511', '5641', '5812', '5999', '5691', '3007', '5192', '5921', '5992', '5451', '5722', '7832', '8299', '5733', '4722', '5532', '5814', '5964', '7997', '5441', '7512', '7999', '5945', '7941', '4511', '4112', '3089', '5941', '4814', '5944', '7299', '6300', '5533', '5713', '4816', '5947', '8021', '9399', '5661'] 
    CLIENT_COLS = ['client_id', 'gender', 'age']
    MERCHANT_COLS = ['merchant_id', 'latitude', 'longitude', 'mcc_id']
    TRANSACTION_COLS = CLIENT_COLS + MERCHANT_COLS + ['transaction_dttm', 'transaction_amt']
    TIME_FORMAT = '%Y-%m-%d %H:%M:%S'
    
    def __init__(self, n_clients, n_transactions, n_merchants, filename):
        self.n_clients=int(n_clients) 
        self.n_transactions=int(n_transactions)
        self.n_merchants=int(n_merchants)
        self.filename = filename
        self.transactions = []
        self.clients = self._generate_clients()
        self.merchants = self._generate_merchants()
        self._generate_transactions()
        
    def get_csv(self):
        transactions = pd.DataFrame(self.transactions, columns=self.TRANSACTION_COLS)
        transactions = transactions.astype({"merchant_id": int, "mcc_cd": int})
        transactions.to_csv(self.filename, encoding='utf-8', index=False)
        
    def _generate_transactions(self):
        for _ in range(self.n_transactions):
            client = list(self.clients.sample(n=1).values[0])
            merchant = list(self.merchants.sample(n=1).values[0])
            transaction = client + merchant
            transaction.append(self._random_time('2022-01-01 00:00:00', '2023-04-01 01:00:00', random.random()))
            transaction.append(round(random.uniform(100.00, 10000.00),2))
            self.transactions.append(tuple(transaction))
        
    def _generate_clients(self):
        ids = [i for i in range(1, self.n_clients + 1)]
        gens = [random.choice(['f', 'm']) for i in range(self.n_clients)]
        ages = [random.randint(14, 101) for i in range(self.n_clients)]
        list_tuples=list(zip(ids, gens, ages))
        return pd.DataFrame(list_tuples, columns=self.CLIENT_COLS)
    
    def _generate_merchants(self):
        ids = [i for i in range(1, self.n_merchants + 1)]
        lats, longs = [], []
        points = self._polygon_random_points(self.n_merchants)
        for p in points:
            lats.append(p.x)
            longs.append(p.y)
        mcc_cds = [int(random.choice(self.MCC_LIST)) for i in range(self.n_merchants)]
        list_tuples=list(zip(ids, lats, longs, mcc_cds))
        return pd.DataFrame(list_tuples, columns=self.MERCHANT_COLS)
        
    def _polygon_random_points(self, num_points):
        min_x, min_y, max_x, max_y = self.MOSCOW_POLY.bounds
        points = []
        while len(points) < num_points:
            random_point = Point([random.uniform(min_x, max_x), random.uniform(min_y, max_y)])
            if (random_point.within(self.MOSCOW_POLY)):
                points.append(random_point)
        return points

    def _random_time(self, start, end, prop):
        stime = time.mktime(time.strptime(start, self.TIME_FORMAT))
        etime = time.mktime(time.strptime(end, self.TIME_FORMAT))

        ptime = stime + prop * (etime - stime)

        return time.strftime(self.TIME_FORMAT, time.localtime(ptime))




if __name__ == '__main__':
    GenerateTestCSV(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]).get_csv()
