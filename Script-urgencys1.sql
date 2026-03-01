-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE specialty (
    specialty_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL
);

CREATE TABLE doctor (
    doctor_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         VARCHAR(100) NOT NULL,
    specialty_id UUID NOT NULL REFERENCES specialty(specialty_id)
);

CREATE TABLE patient (
    patient_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       VARCHAR(100) NOT NULL,
    birthdate  DATE
);

CREATE TABLE appointment (
    appointment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id      UUID NOT NULL REFERENCES doctor(doctor_id),
    patient_id     UUID NOT NULL REFERENCES patient(patient_id),
    appointment_date TIMESTAMP NOT NULL,
    cost           NUMERIC(10,2) NOT NULL
);

CREATE TABLE payment (
    payment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointment(appointment_id),
    amount         NUMERIC(10,2) NOT NULL,
    method         VARCHAR(50) NOT NULL,  -- 'cash', 'card', 'transfer'
    paid_at        TIMESTAMP DEFAULT NOW()
);

CREATE TABLE prescription (
    prescription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id  UUID NOT NULL REFERENCES appointment(appointment_id),
    medication      VARCHAR(150) NOT NULL,
    dosage          VARCHAR(100)
);


---------PATY 2-----
-- 20 especialidades
INSERT INTO specialty (name)
SELECT 'Specialty_' || i FROM generate_series(1, 20) AS i;

-- 200 doctores
INSERT INTO doctor (name, specialty_id)
SELECT 
    'Doctor_' || i,
    (SELECT specialty_id FROM specialty ORDER BY random() LIMIT 1)
FROM generate_series(1, 200) AS i;

-- 1000 pacientes
INSERT INTO patient (name, birthdate)
SELECT 
    'Patient_' || i,
    NOW() - (random() * INTERVAL '30000 days')
FROM generate_series(1, 1000) AS i;

-- 15000 citas
INSERT INTO appointment (doctor_id, patient_id, appointment_date, cost)
SELECT
    (SELECT doctor_id FROM doctor ORDER BY random() LIMIT 1),
    (SELECT patient_id FROM patient ORDER BY random() LIMIT 1),
    NOW() - (random() * INTERVAL '1000 days'),
    (random() * 200 + 50)::NUMERIC(10,2)
FROM generate_series(1, 15000);

-- 15000 pagos (1 por cita)
INSERT INTO payment (appointment_id, amount, method)
SELECT 
    appointment_id,
    cost,
    (ARRAY['cash','card','transfer'])[floor(random()*3+1)]
FROM appointment;

-- Entre 0 y 3 recetas por cita
INSERT INTO prescription (appointment_id, medication, dosage)
SELECT
    appointment_id,
    'Medication_' || floor(random()*100+1),
    floor(random()*3+1) || 'mg'
FROM appointment,
     generate_series(1, floor(random()*3+1)::int);



-------------PART 3----------
-- 1. Total gastado por paciente
SELECT p.patient_id, p.name, SUM(pay.amount) AS total_spent
FROM patient p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN payment pay ON a.appointment_id = pay.appointment_id
GROUP BY p.patient_id, p.name
ORDER BY total_spent DESC;

-- 2. Total de citas por especialidad
SELECT s.name AS specialty, COUNT(a.appointment_id) AS total_appointments
FROM specialty s
JOIN doctor d ON s.specialty_id = d.specialty_id
JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY s.name
ORDER BY total_appointments DESC;

-- 3. Doctor con mayor ingreso generado
SELECT d.doctor_id, d.name, SUM(pay.amount) AS total_revenue
FROM doctor d
JOIN appointment a ON d.doctor_id = a.doctor_id
JOIN payment pay ON a.appointment_id = pay.appointment_id
GROUP BY d.doctor_id, d.name
ORDER BY total_revenue DESC
LIMIT 1;

-- 4. Promedio de costo por especialidad
SELECT s.name AS specialty, ROUND(AVG(a.cost), 2) AS avg_cost
FROM specialty s
JOIN doctor d ON s.specialty_id = d.specialty_id
JOIN appointment a ON d.doctor_id = a.doctor_id
GROUP BY s.name;

-- 5. Top 5 pacientes con más recetas
SELECT p.patient_id, p.name, COUNT(pr.prescription_id) AS total_prescriptions
FROM patient p
JOIN appointment a ON p.patient_id = a.patient_id
JOIN prescription pr ON a.appointment_id = pr.appointment_id
GROUP BY p.patient_id, p.name
ORDER BY total_prescriptions DESC
LIMIT 5;

-- 6. Ingresos por método de pago
SELECT method, SUM(amount) AS total_income
FROM payment
GROUP BY method;


----------PART 4-----------
-- Vista resumen de pacientes
CREATE VIEW patient_summary AS
SELECT 
    p.patient_id,
    p.name,
    COUNT(a.appointment_id)   AS total_appointments,
    SUM(pay.amount)           AS total_spent
FROM patient p
JOIN appointment a  ON p.patient_id = a.patient_id
JOIN payment pay    ON a.appointment_id = pay.appointment_id
GROUP BY p.patient_id, p.name;

-- Vista resumen de ingresos por doctor
CREATE VIEW doctor_revenue_summary AS
SELECT 
    d.doctor_id,
    d.name        AS doctor_name,
    s.name        AS specialty,
    COUNT(a.appointment_id) AS total_appointments,
    SUM(pay.amount)         AS total_revenue
FROM doctor d
JOIN specialty s ON d.specialty_id = s.specialty_id
JOIN appointment a ON d.doctor_id = a.doctor_id
JOIN payment pay   ON a.appointment_id = pay.appointment_id
GROUP BY d.doctor_id, d.name, s.name;

-- Doctores con más de 50 citas
SELECT * FROM doctor_revenue_summary WHERE total_appointments > 50;

-- Pacientes con más de 10 citas
SELECT * FROM patient_summary WHERE total_appointments > 10;


--------------PART 5---------------
EXPLAIN ANALYZE
SELECT d.doctor_id, d.name, SUM(pay.amount) AS total_revenue
FROM doctor d
JOIN appointment a ON d.doctor_id = a.doctor_id
JOIN payment pay ON a.appointment_id = pay.appointment_id
GROUP BY d.doctor_id, d.name
ORDER BY total_revenue DESC;


--------------PART 6---------------
CREATE INDEX idx_appointment_patient_id ON appointment(patient_id);
CREATE INDEX idx_appointment_doctor_id  ON appointment(doctor_id);
CREATE INDEX idx_payment_appointment_id ON payment(appointment_id);
CREATE INDEX idx_doctor_specialty_id    ON doctor(specialty_id);








