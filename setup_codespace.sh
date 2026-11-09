#!/bin/bash
# Run inside /workspace/project of the Codespace (Salon Appointment Scheduler)
# Run it from the root folder of the CodeRoad workspace for this project
echo "Working in: $(pwd)"
cat > salon.sh <<'SCRIPT'
#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # list services as "#) name"
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES" | while read SERVICE_ID BAR NAME
  do
    if [[ -n $SERVICE_ID ]]
    then
      echo "$SERVICE_ID) $NAME"
    fi
  done

  read SERVICE_ID_SELECTED

  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi

  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  if [[ -z $SERVICE_NAME ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
    return
  fi
  SERVICE_NAME=$(echo $SERVICE_NAME | sed -E 's/^ *| *$//g')

  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
  fi
  CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME

  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU
SCRIPT
chmod +x salon.sh
psql -U freecodecamp -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='salon'" | grep -q 1 || { psql -U freecodecamp -d postgres -c "CREATE DATABASE salon"; psql -U freecodecamp -d salon <<'SQL'
CREATE TABLE customers(customer_id SERIAL PRIMARY KEY, phone VARCHAR(20) UNIQUE NOT NULL, name VARCHAR(50) NOT NULL);
CREATE TABLE services(service_id SERIAL PRIMARY KEY, name VARCHAR(50) NOT NULL);
CREATE TABLE appointments(appointment_id SERIAL PRIMARY KEY, customer_id INT NOT NULL REFERENCES customers(customer_id), service_id INT NOT NULL REFERENCES services(service_id), time VARCHAR(20) NOT NULL);
INSERT INTO services(name) VALUES ('cut'), ('color'), ('perm'), ('style'), ('trim');
SQL
}
echo "salon.sh ready. Now click Run in CodeRoad."
