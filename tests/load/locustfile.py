from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    # Wartezeit zwischen den Tasks (simuliert echten User)
    wait_time = between(1, 3)

    @task(1)
    def index(self):
        self.client.get("/")

    @task(3)
    def db_test(self):
        # Dieser Endpoint erzeugt Last auf der DB
        self.client.get("/db-test")

    @task(1)
    def health(self):
        self.client.get("/health")
