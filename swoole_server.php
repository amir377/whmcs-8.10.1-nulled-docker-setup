<?php

use Swoole\Http\Server;

$http = new Server("0.0.0.0", 9090);

$http->on("request", function ($request, $response) {
    $apacheHost = "127.0.0.1";
    $apachePort = 80;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "http://$apacheHost:$apachePort" . $request->server['request_uri']);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $request->server['request_method']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, true); // Include headers in the response

    // Forward headers
    $headers = [];
    foreach ($request->header as $key => $value) {
        $headers[] = "$key: $value";
    }
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    if ($request->server['request_method'] === 'POST') {
        curl_setopt($ch, CURLOPT_POSTFIELDS, $request->rawContent());
    }

    $responseFromApache = curl_exec($ch);
    $statusCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    // Split headers and body
    $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    $headers = substr($responseFromApache, 0, $headerSize);
    $body = substr($responseFromApache, $headerSize);

    // Check if the response is Gzipped
    if (strpos($headers, "Content-Encoding: gzip") !== false) {
        $body = gzdecode($body); // Decompress the body
    }

    curl_close($ch);

    // Send response to Nginx
    $response->status($statusCode);
    $response->end($body);
});

$http->start();
