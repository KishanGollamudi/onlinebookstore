package com.bittercode.util;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

class DatabaseConfig {

    static Properties prop = new Properties();
    static {

        ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
        InputStream input = classLoader.getResourceAsStream("application.properties");

        try {
            prop.load(input);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public final static String DRIVER_NAME = getConfigValue("db.driver", "DB_DRIVER");
    public final static String DB_HOST = getConfigValue("db.host", "DB_HOST");
    public final static String DB_PORT = getConfigValue("db.port", "DB_PORT");
    public final static String DB_NAME = getConfigValue("db.name", "DB_NAME");
    public final static String DB_USER_NAME = getConfigValue("db.username", "DB_USERNAME");
    public final static String DB_PASSWORD = getConfigValue("db.password", "DB_PASSWORD");
    public final static String CONNECTION_STRING = DB_HOST + ":" + DB_PORT + "/" + DB_NAME;

    /**
     * Allows Docker deployments to override the local configuration using JVM
     * properties or environment variables.
     */
    private static String getConfigValue(String propertyName, String environmentName) {
        String value = System.getProperty(propertyName);
        if (value == null || value.isBlank()) {
            value = System.getenv(environmentName);
        }
        return value == null || value.isBlank() ? prop.getProperty(propertyName) : value;
    }

}
