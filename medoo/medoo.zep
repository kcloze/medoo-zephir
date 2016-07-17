namespace MyApp\Library;

use PDOException;
use Exception;
use PDO;


/*!
 * Medoo database framework
 * http://medoo.in
 * Version 1.1.2
 *
 * Copyright 2016, Angel Lai
 * Released under the MIT license
 */
class Medoo
{
    // General
    protected database_type;
    protected charset;
    protected database_name;
    // For MySQL, MariaDB, MSSQL, Sybase, PostgreSQL, Oracle
    protected server;
    protected username;
    protected password;
    // For SQLite
    protected database_file;
    // For MySQL or MariaDB with unix_socket
    protected socket;
    // Optional
    protected port;
    protected prefix;
    protected option = [];
    // Variable
    protected logs = [];
    protected debug_mode = false;
    public function __construct(options = null)
    {
        var commands, dsn, option, value, port, type, is_port, dbname, tmpArrayc6d951ed1f79d761ca5018bc0b4e1285, e;
    
        try {
            let commands =  [];
            let dsn = "";
            if is_array(options) {
                for option, value in options {
                    let this->{option} = value;
                }
            } else {
                return false;
            }
            if isset this->port && is_int(this->port * 1) {
                let port =  this->port;
            }
            let type =  strtolower(this->database_type);
            let is_port =  isset port;
            if isset options["prefix"] {
                let this->prefix = options["prefix"];
            }
            switch (type) {
                case "mariadb":
                    let type = "mysql";
                case "mysql":
                    if this->socket {
                        let dsn =  type . ":unix_socket=" . this->socket . ";dbname=" . this->database_name;
                    } else {
                        let dsn =  type . ":host=" . this->server . ( is_port ? ";port=" . port  : "") . ";dbname=" . this->database_name;
                    }
                    // Make MySQL using standard quoted identifier
                    let commands[] = "SET SQL_MODE=ANSI_QUOTES";
                    break;
                case "pgsql":
                    let dsn =  type . ":host=" . this->server . ( is_port ? ";port=" . port  : "") . ";dbname=" . this->database_name;
                    break;
                case "sybase":
                    let dsn =  "dblib:host=" . this->server . ( is_port ? ":" . port  : "") . ";dbname=" . this->database_name;
                    break;
                case "oracle":
                    let dbname =  this->server ? "//" . this->server . ( is_port ? ":" . port  : ":1521") . "/" . this->database_name  : this->database_name;
                    let dsn =  "oci:dbname=" . dbname . ( this->charset ? ";charset=" . this->charset  : "");
                    break;
                case "mssql":
                    let dsn =  strstr(PHP_OS, "WIN") ? "sqlsrv:server=" . this->server . ( is_port ? "," . port  : "") . ";database=" . this->database_name  : "dblib:host=" . this->server . ( is_port ? ":" . port  : "") . ";dbname=" . this->database_name;
                    // Keep MSSQL QUOTED_IDENTIFIER is ON for standard quoting
                    let commands[] = "SET QUOTED_IDENTIFIER ON";
                    break;
                case "sqlite":
                    let dsn =  type . ":" . this->database_file;
                    let this->username =  null;
                    let this->password =  null;
                    break;
            }
            let tmpArrayc6d951ed1f79d761ca5018bc0b4e1285 = ["mariadb", "mysql", "pgsql", "sybase", "mssql"];
            if in_array(type, tmpArrayc6d951ed1f79d761ca5018bc0b4e1285) && this->charset {
                let commands[] =  "SET NAMES '" . this->charset . "'";
            }
            let this->pdo =  new pdo(dsn, this->username, this->password, this->option);
            for value in commands {
                this->pdo->exec(value);
            }
        } catch PDOException, e {
            throw new Exception(e->getMessage());
        }
    }
    
    public function query(query)
    {
        if this->debug_mode {
            echo query;
            let this->debug_mode =  false;
            return false;
        }
        let this->logs[] = query;
        return this->pdo->query(query);
    }
    
    public function exec(query)
    {
        if this->debug_mode {
            echo query;
            let this->debug_mode =  false;
            return false;
        }
        let this->logs[] = query;
        return this->pdo->exec(query);
    }
    
    public function quote(stringg)
    {
        return this->pdo->quote(stringg);
    }
    
    protected function tableQuote(table)
    {
        return "\"" . this->prefix . table . "\"";
    }
    
    protected function columnQuote(stringg)
    {
        preg_match("/(\\(JSON\\)\\s*|^#)?([a-zA-Z0-9_]*)\\.([a-zA-Z0-9_]*)/", stringg, column_match);
        if isset column_match[2], column_match[3] {
            return "\"" . this->prefix . column_match[2] . "\".\"" . column_match[3] . "\"";
        }
        return "\"" . stringg . "\"";
    }
    
    protected function columnPush(columns)
    {
        var stack, key, value;
    
        if columns == "*" {
            return columns;
        }
        if is_string(columns) {
            let columns =  [columns];
        }
        let stack =  [];
        for key, value in columns {
            if is_array(value) {
                let stack[] =  this->columnPush(value);
            } else {
                preg_match("/([a-zA-Z0-9_\\-\\.]*)\\s*\\(([a-zA-Z0-9_\\-]*)\\)/i", value, match);
                if isset match[1], match[2] {
                    let stack[] =  this->columnQuote(match[1]) . " AS " . this->columnQuote(match[2]);
                    let columns[key] = match[2];
                } else {
                    let stack[] =  this->columnQuote(value);
                }
            }
        }
        return implode(stack, ",");
    }
    
    protected function arrayQuote(myArray)
    {
        var temp, value;
    
        let temp =  [];
        for value in myArray {
            let temp[] =  is_int(value) ? value  : this->pdo->quote(value);
        }
        return implode(temp, ",");
    }
    
    protected function innerConjunct(data, conjunctor, outer_conjunctor)
    {
        var haystack, value;
    
        let haystack =  [];
        for value in data {
            let haystack[] =  "(" . this->dataImplode(value, conjunctor) . ")";
        }
        return implode(outer_conjunctor . " ", haystack);
    }
    
    protected function fnQuote(column, stringg)
    {
        return  strpos(column, "#") === 0 && preg_match("/^[A-Z0-9\\_]*\\([^)]*\\)$/", stringg) ? stringg  : this->quote(stringg);
    }
    
    protected function dataImplode(data, conjunctor, outer_conjunctor = null)
    {
        var wheres, key, value, type, column, operator, like_clauses, item, suffix, tmpArray23169cf3b14d64f0a6e1af7831f8e941;
    
        let wheres =  [];
        for key, value in data {
            let type =  gettype(value);
            if preg_match("/^(AND|OR)(\\s+#.*)?$/i", key, relation_match) && type == "array" {
                let wheres[] =  0 !== count(array_diff_key(value, array_keys(array_keys(value)))) ? "(" . this->dataImplode(value, " " . relation_match[1]) . ")"  : "(" . this->innerConjunct(value, " " . relation_match[1], conjunctor) . ")";
            } else {
                preg_match("/(#?)([\\w\\.\\-]+)(\\[(\\>|\\>\\=|\\<|\\<\\=|\\!|\\<\\>|\\>\\<|\\!?~)\\])?/i", key, match);
                let column =  this->columnQuote(match[2]);
                if isset match[4] {
                    let operator = match[4];
                    if operator == "!" {
                        switch (type) {
                            case "NULL":
                                let wheres[] =  column . " IS NOT NULL";
                                break;
                            case "array":
                                let wheres[] =  column . " NOT IN (" . this->arrayQuote(value) . ")";
                                break;
                            case "integer":
                            case "double":
                                let wheres[] =  column . " != " . value;
                                break;
                            case "boolean":
                                let wheres[] =  column . " != " . ( value ? "1"  : "0");
                                break;
                            case "string":
                                let wheres[] =  column . " != " . this->fnQuote(key, value);
                                break;
                        }
                    }
                    if operator == "<>" || operator == "><" {
                        if type == "array" {
                            if operator == "><" {
                                let column .= " NOT";
                            }
                            if is_numeric(value[0]) && is_numeric(value[1]) {
                                let wheres[] =  "(" . column . " BETWEEN " . value[0] . " AND " . value[1] . ")";
                            } else {
                                let wheres[] =  "(" . column . " BETWEEN " . this->quote(value[0]) . " AND " . this->quote(value[1]) . ")";
                            }
                        }
                    }
                    if operator == "~" || operator == "!~" {
                        if type != "array" {
                            let value =  [value];
                        }
                        let like_clauses =  [];
                        for item in value {
                            let item =  strval(item);
                            let suffix =  mb_substr(item, -1, 1);
                            if preg_match("/^(?!(%|\\[|_])).+(?<!(%|\\]|_))$/", item) {
                                let item =  "%" . item . "%";
                            }
                            let like_clauses[] =  column . ( operator === "!~" ? " NOT"  : "") . " LIKE " . this->fnQuote(key, item);
                        }
                        let wheres[] =  implode(" OR ", like_clauses);
                    }
                    let tmpArray23169cf3b14d64f0a6e1af7831f8e941 = [">", ">=", "<", "<="];
                    if in_array(operator, tmpArray23169cf3b14d64f0a6e1af7831f8e941) {
                        if is_numeric(value) {
                            let wheres[] =  column . " " . operator . " " . value;
                        } elseif strpos(key, "#") === 0 {
                            let wheres[] =  column . " " . operator . " " . this->fnQuote(key, value);
                        } else {
                            let wheres[] =  column . " " . operator . " " . this->quote(value);
                        }
                    }
                } else {
                    switch (type) {
                        case "NULL":
                            let wheres[] =  column . " IS NULL";
                            break;
                        case "array":
                            let wheres[] =  column . " IN (" . this->arrayQuote(value) . ")";
                            break;
                        case "integer":
                        case "double":
                            let wheres[] =  column . " = " . value;
                            break;
                        case "boolean":
                            let wheres[] =  column . " = " . ( value ? "1"  : "0");
                            break;
                        case "string":
                            let wheres[] =  column . " = " . this->fnQuote(key, value);
                            break;
                    }
                }
            }
        }
        return implode(conjunctor . " ", wheres);
    }
    
    protected function whereClause(where)
    {
        var where_clause, where_keys, where_AND, where_OR, single_condition, tmpArrayce5f81eb43856cf703c3f6747305324b, tmpArray40cd750bba9870f18aada2478b24840a, condition, value, match, order, stack, column, limit;
    
        let where_clause = "";
        if is_array(where) {
            let where_keys =  array_keys(where);
            let where_AND =  preg_grep("/^AND\\s*#?$/i", where_keys);
            let where_OR =  preg_grep("/^OR\\s*#?$/i", where_keys);
            let tmpArrayce5f81eb43856cf703c3f6747305324b = ["AND", "OR", "GROUP", "ORDER", "HAVING", "LIMIT", "LIKE", "MATCH"];
            let single_condition =  array_diff_key(where, array_flip(tmpArrayce5f81eb43856cf703c3f6747305324b));
            let tmpArray40cd750bba9870f18aada2478b24840a = [];
            if single_condition != tmpArray40cd750bba9870f18aada2478b24840a {
                let condition =  this->dataImplode(single_condition, "");
                if condition != "" {
                    let where_clause =  " WHERE " . condition;
                }
            }
            if !(empty(where_AND)) {
                let value =  array_values(where_AND);
                let where_clause =  " WHERE " . this->dataImplode(where[value[0]], " AND");
            }
            if !(empty(where_OR)) {
                let value =  array_values(where_OR);
                let where_clause =  " WHERE " . this->dataImplode(where[value[0]], " OR");
            }
            if isset where["MATCH"] {
                let match = where["MATCH"];
                if is_array(match) && isset match["columns"], match["keyword"] {
                    let where_clause .= ( where_clause != "" ? " AND "  : " WHERE ") . " MATCH (\"" . str_replace(".", "\".\"", implode(match["columns"], "\", \"")) . "\") AGAINST (" . this->quote(match["keyword"]) . ")";
                }
            }
            if isset where["GROUP"] {
                let where_clause .= " GROUP BY " . this->columnQuote(where["GROUP"]);
                if isset where["HAVING"] {
                    let where_clause .= " HAVING " . this->dataImplode(where["HAVING"], " AND");
                }
            }
            if isset where["ORDER"] {
                let order = where["ORDER"];
                if is_array(order) {
                    let stack =  [];
                    for column, value in order {
                        if is_array(value) {
                            let stack[] =  "FIELD(" . this->columnQuote(column) . ", " . this->arrayQuote(value) . ")";
                        } else {
                            if value === "ASC" || value === "DESC" {
                                let stack[] =  this->columnQuote(column) . " " . value;
                            } else {
                                if is_int(column) {
                                    let stack[] =  this->columnQuote(value);
                                }
                            }
                        }
                    }
                    let where_clause .= " ORDER BY " . implode(stack, ",");
                } else {
                    let where_clause .= " ORDER BY " . this->columnQuote(order);
                }
            }
            if isset where["LIMIT"] {
                let limit = where["LIMIT"];
                if is_numeric(limit) {
                    let where_clause .= " LIMIT " . limit;
                }
                if is_array(limit) && is_numeric(limit[0]) && is_numeric(limit[1]) {
                    if this->database_type === "pgsql" {
                        let where_clause .= " OFFSET " . limit[0] . " LIMIT " . limit[1];
                    } else {
                        let where_clause .= " LIMIT " . limit[0] . "," . limit[1];
                    }
                }
            }
        } else {
            if where != null {
                let where_clause .= " " . where;
            }
        }
        return where_clause;
    }
    
    protected function selectContext(table, join, columns = null, where = null, column_fn = null)
    {
        var table_query, join_key, table_join, join_array, sub_table, relation, joins, key, value, table_name, column;
    
        preg_match("/([a-zA-Z0-9_\\-]*)\\s*\\(([a-zA-Z0-9_\\-]*)\\)/i", table, table_match);
        if isset table_match[1], table_match[2] {
            let table =  this->tableQuote(table_match[1]);
            let table_query =  this->tableQuote(table_match[1]) . " AS " . this->tableQuote(table_match[2]);
        } else {
            let table =  this->tableQuote(table);
            let table_query = table;
        }
        let join_key =  is_array(join) ? array_keys(join)  : null;
        if isset join_key[0] && strpos(join_key[0], "[") === 0 {
            let table_join =  [];
            let join_array =  [">" : "LEFT", "<" : "RIGHT", "<>" : "FULL", "><" : "INNER"];
            for sub_table, relation in join {
                preg_match("/(\\[(\\<|\\>|\\>\\<|\\<\\>)\\])?([a-zA-Z0-9_\\-]*)\\s?(\\(([a-zA-Z0-9_\\-]*)\\))?/", sub_table, match);
                if match[2] != "" && match[3] != "" {
                    if is_string(relation) {
                        let relation =  "USING (\"" . relation . "\")";
                    }
                    if is_array(relation) {
                        // For ['column1', 'column2']
                        if isset relation[0] {
                            let relation =  "USING (\"" . implode(relation, "\", \"") . "\")";
                        } else {
                            let joins =  [];
                            for key, value in relation {
                                let joins[] =  ( strpos(key, ".") > 0 ? this->columnQuote(key)  : table . ".\"" . key . "\"") . " = " . this->tableQuote( isset match[5] ? match[5]  : match[3]) . ".\"" . value . "\"";
                            }
                            let relation =  "ON " . implode(joins, " AND ");
                        }
                    }
                    let table_name =  this->tableQuote(match[3]) . " ";
                    if isset match[5] {
                        let table_name .= "AS " . this->tableQuote(match[5]) . " ";
                    }
                    let table_join[] =  join_array[match[2]] . " JOIN " . table_name . relation;
                }
            }
            let table_query .= " " . implode(table_join, " ");
        } else {
            if is_null(columns) {
                if is_null(where) {
                    if is_array(join) && isset column_fn {
                        let where = join;
                        let columns =  null;
                    } else {
                        let where =  null;
                        let columns = join;
                    }
                } else {
                    let where = join;
                    let columns =  null;
                }
            } else {
                let where = columns;
                let columns = join;
            }
        }
        if isset column_fn {
            if column_fn == 1 {
                let column = "1";
                if is_null(where) {
                    let where = columns;
                }
            } else {
                if empty(columns) {
                    let columns = "*";
                    let where = join;
                }
                let column =  column_fn . "(" . this->columnPush(columns) . ")";
            }
        } else {
            let column =  this->columnPush(columns);
        }
        return "SELECT " . column . " FROM " . table_query . this->whereClause(where);
    }
    
    protected function dataMap(index, key, value, data, stack) -> void
    {
        var sub_stack, sub_key, sub_value, current_stack;
    
        if is_array(value) {
            let sub_stack =  [];
            for sub_key, sub_value in value {
                if is_array(sub_value) {
                    let current_stack = stack[index][key];
                    this->dataMap(false, sub_key, sub_value, data, current_stack);
                    let stack[index][key][sub_key] = current_stack[0][sub_key];
                } else {
                    this->dataMap(false, preg_replace("/^[\\w]*\\./i", "", sub_value), sub_key, data, sub_stack);
                    let stack[index][key] = sub_stack;
                }
            }
        } else {
            if index !== false {
                let stack[index][value] = data[value];
            } else {
                let stack[key] = data[key];
            }
        }
    }
    
    public function select(table, join, columns = null, where = null)
    {
        var column, is_single_column, query, stack, index, row, key, value;
    
        let column =  where == null ? join  : columns;
        let is_single_column =  is_string(column) && column !== "*";
        let query =  this->query(this->selectContext(table, join, columns, where));
        let stack =  [];
        let index = 0;
        if !(query) {
            return false;
        }
        if columns === "*" {
            return query->fetchAll(pdo::FETCH_ASSOC);
        }
        if is_single_column {
            return query->fetchAll(pdo::FETCH_COLUMN);
        }
        let row =  query->fetch(pdo::FETCH_ASSOC);
        while (row) {
            for key, value in columns {
                if is_array(value) {
                    this->dataMap(index, key, value, row, stack);
                } else {
                    this->dataMap(index, key, preg_replace("/^[\\w]*\\./i", "", value), row, stack);
                }
            }
            let index++;
        let row =  query->fetch(pdo::FETCH_ASSOC);
        }
        return stack;
    }
    
    public function insert(table, datas)
    {
        var lastId, data, values, columns, key, value;
    
        let lastId =  [];
        // Check indexed or associative array
        if !(isset datas[0]) {
            let datas =  [datas];
        }
        for data in datas {
            let values =  [];
            let columns =  [];
            for key, value in data {
                let columns[] =  preg_replace("/^(\\(JSON\\)\\s*|#)/i", "", key);
                switch (gettype(value)) {
                    case "NULL":
                        let values[] = "NULL";
                        break;
                    case "array":
                        preg_match("/\\(JSON\\)\\s*([\\w]+)/i", key, column_match);
                        let values[] =  isset column_match[0] ? this->quote(json_encode(value))  : this->quote(serialize(value));
                        break;
                    case "boolean":
                        let values[] =  value ? "1"  : "0";
                        break;
                    case "integer":
                    case "double":
                    case "string":
                        let values[] =  this->fnQuote(key, value);
                        break;
                }
            }
            this->exec("INSERT INTO " . this->tableQuote(table) . " (" . implode(", ", columns) . ") VALUES (" . implode(values, ", ") . ")");
            let lastId[] =  this->pdo->lastInsertId();
        }
        return  count(lastId) > 1 ? lastId  : lastId[0];
    }
    
    public function update(table, data, where = null)
    {
        var fields, key, value, column;
    
        let fields =  [];
        for key, value in data {
            preg_match("/([\\w]+)(\\[(\\+|\\-|\\*|\\/)\\])?/i", key, match);
            if isset match[3] {
                if is_numeric(value) {
                    let fields[] =  this->columnQuote(match[1]) . " = " . this->columnQuote(match[1]) . " " . match[3] . " " . value;
                }
            } else {
                let column =  this->columnQuote(preg_replace("/^(\\(JSON\\)\\s*|#)/i", "", key));
                switch (gettype(value)) {
                    case "NULL":
                        let fields[] =  column . " = NULL";
                        break;
                    case "array":
                        preg_match("/\\(JSON\\)\\s*([\\w]+)/i", key, column_match);
                        let fields[] =  column . " = " . this->quote( isset column_match[0] ? json_encode(value)  : serialize(value));
                        break;
                    case "boolean":
                        let fields[] =  column . " = " . ( value ? "1"  : "0");
                        break;
                    case "integer":
                    case "double":
                    case "string":
                        let fields[] =  column . " = " . this->fnQuote(key, value);
                        break;
                }
            }
        }
        return this->exec("UPDATE " . this->tableQuote(table) . " SET " . implode(", ", fields) . this->whereClause(where));
    }
    
    public function delete(table, where)
    {
        return this->exec("DELETE FROM " . this->tableQuote(table) . this->whereClause(where));
    }
    
    public function replace(table, columns, search = null, replace = null, where = null)
    {
        var replace_query, column, replacements, replace_search, replace_replacement;
    
        if is_array(columns) {
            let replace_query =  [];
            for column, replacements in columns {
                for replace_search, replace_replacement in replacements {
                    let replace_query[] =  column . " = REPLACE(" . this->columnQuote(column) . ", " . this->quote(replace_search) . ", " . this->quote(replace_replacement) . ")";
                }
            }
            let replace_query =  implode(", ", replace_query);
            let where = search;
        } else {
            if is_array(search) {
                let replace_query =  [];
                for replace_search, replace_replacement in search {
                    let replace_query[] =  columns . " = REPLACE(" . this->columnQuote(columns) . ", " . this->quote(replace_search) . ", " . this->quote(replace_replacement) . ")";
                }
                let replace_query =  implode(", ", replace_query);
                let where = replace;
            } else {
                let replace_query =  columns . " = REPLACE(" . this->columnQuote(columns) . ", " . this->quote(search) . ", " . this->quote(replace) . ")";
            }
        }
        return this->exec("UPDATE " . this->tableQuote(table) . " SET " . replace_query . this->whereClause(where));
    }
    
    public function get(table, join = null, columns = null, where = null)
    {
        var column, is_single_column, query, data, stack, key, value;
    
        let column =  where == null ? join  : columns;
        let is_single_column =  is_string(column) && column !== "*";
        let query =  this->query(this->selectContext(table, join, columns, where) . " LIMIT 1");
        if query {
            let data =  query->fetchAll(pdo::FETCH_ASSOC);
            if isset data[0] {
                if is_single_column {
                    return data[0][preg_replace("/^[\\w]*\\./i", "", column)];
                }
                if column === "*" {
                    return data[0];
                }
                let stack =  [];
                for key, value in columns {
                    if is_array(value) {
                        this->dataMap(0, key, value, data[0], stack);
                    } else {
                        this->dataMap(0, key, preg_replace("/^[\\w]*\\./i", "", value), data[0], stack);
                    }
                }
                return stack[0];
            } else {
                return false;
            }
        } else {
            return false;
        }
    }
    
    public function has(table, join, where = null)
    {
        var column, query;
    
        let column =  null;
        let query =  this->query("SELECT EXISTS(" . this->selectContext(table, join, column, where, 1) . ")");
        if query {
            return query->fetchColumn() === "1";
        } else {
            return false;
        }
    }
    
    public function count(table, join = null, column = null, where = null)
    {
        var query;
    
        let query =  this->query(this->selectContext(table, join, column, where, "COUNT"));
        return  query ? 0 + query->fetchColumn()  : false;
    }
    
    public function max(table, join, column = null, where = null)
    {
        var query, max;
    
        let query =  this->query(this->selectContext(table, join, column, where, "MAX"));
        if query {
            let max =  query->fetchColumn();
            return  is_numeric(max) ? max + 0  : max;
        } else {
            return false;
        }
    }
    
    public function min(table, join, column = null, where = null)
    {
        var query, min;
    
        let query =  this->query(this->selectContext(table, join, column, where, "MIN"));
        if query {
            let min =  query->fetchColumn();
            return  is_numeric(min) ? min + 0  : min;
        } else {
            return false;
        }
    }
    
    public function avg(table, join, column = null, where = null)
    {
        var query;
    
        let query =  this->query(this->selectContext(table, join, column, where, "AVG"));
        return  query ? 0 + query->fetchColumn()  : false;
    }
    
    public function sum(table, join, column = null, where = null)
    {
        var query;
    
        let query =  this->query(this->selectContext(table, join, column, where, "SUM"));
        return  query ? 0 + query->fetchColumn()  : false;
    }
    
    public function action(actions)
    {
        var result;
    
        if is_callable(actions) {
            this->pdo->beginTransaction();
            let result =  {actions}(this);
            if result === false {
                this->pdo->rollBack();
            } else {
                this->pdo->commit();
            }
        } else {
            return false;
        }
    }
    
    public function debug()
    {
        let this->debug_mode =  true;
        return this;
    }
    
    public function error()
    {
        return this->pdo->errorInfo();
    }
    
    public function lastQuery()
    {
        return end(this->logs);
    }
    
    public function log()
    {
        return this->logs;
    }
    
    public function info()
    {
        var output, key, value;
    
        let output =  ["server" : "SERVER_INFO", "driver" : "DRIVER_NAME", "client" : "CLIENT_VERSION", "version" : "SERVER_VERSION", "connection" : "CONNECTION_STATUS"];
        for key, value in output {
            let output[key] =  this->pdo->getAttribute(constant("PDO::ATTR_" . value));
        }
        return output;
    }

}