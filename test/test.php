<?php

$config = [
    // required
    'database_type' => 'mysql',
    'database_name' => 'test',
    'server'        => '192.168.9.24',
    'username'      => 'yongfu_b',
    'password'      => '%#@SwEsdf43738',
    'charset'       => 'utf8',

    // [optional]
    'port'          => 3306,

    // [optional] Table prefix
    'prefix'        => '',

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
var_dump("----------------");
$result = preg_match("/([a-zA-Z0-9_\-]*)\s*\(([a-zA-Z0-9_\-]*)\)/i", "users", $table_match);
var_dump($result, $table_match);
$result = preg_match('/([a-zA-Z0-9_\-]*)\s*\(([a-zA-Z0-9_\-]*)\)/i', "users", $table_match);
var_dump($result, $table_match);
