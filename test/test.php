<?php

$config = [
    // required
    'database_type' => 'mysql',
    'database_name' => 'test',
    'server'        => '127.0.0.1',
    'username'      => 'test',
    'password'      => '123kcloze',
    'charset'       => 'utf8',

    // [optional]
    'port'          => 3306,

    // [optional] Table prefix
    'prefix'        => 'PREFIX_',

    // [optional] driver_option for connection, read more from http://www.php.net/manual/en/pdo.setattribute.php
    'option'        => [
        PDO::ATTR_CASE => PDO::CASE_NATURAL,
    ],
];

$database = new \Medoo\Medoo($config);
// $result   = $database->select("users", "name", [
//     "email" => "1468119720",
// ]);
$result = $database->select("users", "name");

var_dump($result);
var_dump($database->log());
