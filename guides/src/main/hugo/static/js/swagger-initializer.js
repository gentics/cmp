window.onload = function() {
  //<editor-fold desc="Changeable Configuration Block">

  // the following lines will be replaced by docker/configurator, when it runs in a docker-container
  window.ui = SwaggerUIBundle({
    urls: [
      {
        url: "../plugins/comment-plugin/openapi.yaml",
        name: "Mesh Comment Plugin"
      },
      {
        url: "../plugins/export-plugin/openapi.yaml",
        name: "Mesh Export Plugin"
      },
      {
        url: "../plugins/favorite-plugin/openapi.yaml",
        name: "Mesh Favorite Plugin"
      },
      {
        url: "../plugins/forms-plugin/openapi.yaml",
        name: "Mesh Forms Plugin"
      },
      {
        url: "../plugins/gcms-plugin/openapi.yaml",
        name: "Mesh GCMS Plugin"
      },
      {
        url: "../plugins/keycloak-plugin/openapi.yaml",
        name: "Mesh Keycloak Plugin"
      },
      {
        url: "../plugins/like-plugin/openapi.yaml",
        name: "Mesh Like Plugin"
      },
      {
        url: "../plugins/mustread-plugin/openapi.yaml",
        name: "Mesh Mustread Plugin"
      },
      {
        url: "../plugins/search-plugin/openapi.yaml",
        name: "Mesh Search Plugin"
      }
    ],
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout"
  });

  //</editor-fold>
};
