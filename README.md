# LTI (Ledger-To-Invest)

**Welcome to LTI (Ledger-To-Invest)** – your all-in-one personal finance companion, built to help you take control of your money and grow your investments with confidence. LTI combines great ledgering tracking with powerful budgeting tools and smart investment tracking, giving you a secure, scalable, and easy-to-use platform for managing your finances.

At the heart of LTI is a unique budgeting philosophy that blends three proven methods into one seamless system:

* **Envelope System** – Plan ahead by assigning a set amount to each spending category.
* **Zero-Based Budgeting** – Give every dollar a purpose — nothing left unallocated.
* **Incremental Budgeting** – Effortlessly carry over any surplus (or shortfall) from one budget to the next.

With LTI, budgeting isn’t just about controlling expenses — it’s about building a strategy for long-term financial growth.

## ✨ Features

* **Smarter Ledgers**: Create tailored ledgers that match your goals.
* **All Your Accounts**: Track checking, savings, credit cards, and investments in one place.
* **Effortless Transactions**: Split categories, transfer funds, and stay organized with ease.
* **Investment Insights**: See asset values, prices, and portfolio performance at a glance.
* **Global Ready**: Manage multiple currencies with automatic exchange rates.
* **Goal-Driven**: Set clear financial targets and track your progress.
* **Clear Reports**: Instantly understand your spending, net worth, and investments.

## 🛠️ Tech Stack

* **Database**: [**PostgreSQL**](https://www.postgresql.org/)
* **Backend**: [**FastAPI**](https://fastapi.tiangolo.com/)
  * **ORM**: [**SQLAlchemy**](https://www.sqlalchemy.org/)
  * **Data Validation**: [**Pydantic**](https://pydantic-docs.helpmanual.io/)
  * **Authentication**: [**python-jose**](https://github.com/mpdavis/python-jose) for JWT and [**passlib**](https://passlib.readthedocs.io/en/stable/) for hashing
  * **ASGI Server**: [**Uvicorn**](https://www.uvicorn.org/)
* **Frontend**: [**React**](https://react.dev/)
  * **Build Tool**: [**Vite**](https://vite.dev/)
  * **CSS**: [**Tailwind CSS**](https://tailwindcss.com/)
* **Container**: [**Docker**](https://www.docker.com/)
  * **Multi-Container**: [**Docker Compose**](https://docs.docker.com/compose/)

## 🚀 Getting Started

1. Clone the repository
2. Create environment file: `.env`
3. Start the application: `make up`
<!-- 3. Build the application: `make build` -->
<!-- 2. Copy environment file: `cp .env.example .env` -->

The application will be available at:

* Frontend: <http://localhost:3000>
* Backend API: <http://localhost:8000>
* API Documentation: <http://localhost:8000/docs>

## Development

* `make up` - Start all services
* `make logs` - View logs
<!-- - `make test` - Run backend tests -->
<!-- - `make shell-backend` - Access backend container -->
<!-- - `make shell-frontend` - Access frontend container -->

## 📂 Project Structure

* `database/` - Database initialization
* `backend/` - FastAPI application
* `frontend/` - React application
<!-- - `scripts/` - Utility scripts -->