<?php

// Define the output file
$outputFile = '/var/www/html/configuration.php';

// Check if the template exists
$templateFile = '/var/www/html/docker/config/configuration.php.template';
if (!file_exists($templateFile)) {
    die("Template file not found: $templateFile\n");
}

// Read the template file
$template = file_get_contents($templateFile);

// Replace placeholders with environment variable values
$replacements = [
    '{{LICENCE}}' => getenv('LICENCE') ?: '',
    '{{DB_HOST}}' => getenv('DB_HOST') ?: '',
    '{{DB_PORT}}' => getenv('DB_PORT') ?: '',
    '{{DB_USERNAME}}' => getenv('DB_USERNAME') ?: '',
    '{{DB_PASSWORD}}' => getenv('DB_PASSWORD') ?: '',
    '{{DB_NAME}}' => getenv('DB_NAME') ?: '',
    '{{DB_TLS_CA}}' => getenv('DB_TLS_CA') ?: '',
    '{{DB_TLS_CA_PATH}}' => getenv('DB_TLS_CA_PATH') ?: '',
    '{{DB_TLS_CERT}}' => getenv('DB_TLS_CERT') ?: '',
    '{{DB_TLS_CIPHER}}' => getenv('DB_TLS_CIPHER') ?: '',
    '{{DB_TLS_KEY}}' => getenv('DB_TLS_KEY') ?: '',
    '{{DB_TLS_VERIFY_CERT}}' => getenv('DB_TLS_VERIFY_CERT') ?: '',
    '{{MYSQL_CHARSET}}' => getenv('MYSQL_CHARSET') ?: '',
    '{{CC_ENCRYPTION_HASH}}' => getenv('CC_ENCRYPTION_HASH') ?: '',
    '{{TEMPLATES_COMPILEDIR}}' => getenv('TEMPLATES_COMPILEDIR') ?: '',
];

// Perform the replacement
foreach ($replacements as $placeholder => $value) {
    $template = str_replace($placeholder, $value, $template);
}

// Write to the output file
file_put_contents($outputFile, $template);
chmod($outputFile, 0644); // Set the correct permissions

echo "Configuration generated successfully.\n";
