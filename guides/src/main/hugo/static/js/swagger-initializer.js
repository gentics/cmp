window.onload = function() {
  //<editor-fold desc="Changeable Configuration Block">

  // the following lines will be replaced by docker/configurator, when it runs in a docker-container
  window.ui = SwaggerUIBundle({
    urls: [
      {
        url: "../cms-oss/openapi.yaml",
        name: "Gentics CMS OSS"
      },
      {
        url: "../cms-ee/openapi.yaml",
        name: "Gentics CMS EE"
      },
      {
        url: "../mesh/openapi.yaml",
        name: "Gentics Mesh"
      },
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
      },
      {
        url: "../portal-java/examples/api/openapi.yaml",
        name: "Gentics Portal | Java"
      },
      {
        url: "../portal-php/examples/api/openapi.yaml",
        name: "Gentics Portal | PHP"
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
