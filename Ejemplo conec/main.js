const {Client} = require('pg');

const express = require('express');

const app = express();
const port = 3000;

app.use(express.json());

const conection = new Client({
    user: 'riwi_cohorte_6',
    host: '51.222.142.204',
    database: 'richie_ft_tesla',
    password: 'Riwi2026+',
    port: 5432,
});

conection.connect().then(() => {
    console.log('Conexión exitosa a la base de datos');
}).catch((err) => {
    console.error('Error al conectar a la base de datos', err);
});


app.post('/api/patient', async (req, res) => {

    const {patient_id, name, birthdate} = req.body;
    try {
        const query = 'INSERT INTO guty2.patient (patient_id, name, birthdate) VALUES ($1, $2, $3) RETURNING *';
        const values = [patient_id, name, birthdate];
        const result = await conection.query(query, values);
        res.status(201).json(result.rows[0]);
    } catch (err) {
        console.error('Error al insertar datos', err);
        res.status(500).json({error: 'Error al insertar datos'});
    }

    conection.query('SELECT * FROM guty2.patient', (err, result) => {
        if (err) {
            console.error('Error al consultar datos', err);
            res.status(500).json({error: 'Error al consultar datos'});
        } else {
            console.log('Datos de la tabla patient:', result.rows);
        }
    });
});

app.listen(port, () => {
    console.log(`Servidor escuchando en http://localhost:${port}`);
});
