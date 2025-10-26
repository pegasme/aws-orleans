using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc.ApiExplorer;
using Swashbuckle.AspNetCore.Swagger;
using Swashbuckle.AspNetCore.SwaggerGen;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Mvc.Authorization;

namespace AdventureClient.Utilities;

public class HeaderSwaggerAttribute : IOperationFilter
  {   
      public void Apply(OpenApiOperation operation, OperationFilterContext context)
      {
          if (operation.Parameters == null)
              operation.Parameters = new List<OpenApiParameter>();
 
          operation.Parameters.Add(new OpenApiParameter
          {
              Name = "Authorization",
              In = ParameterLocation.Header,
              Required = false,
              Schema = new OpenApiSchema
              {
                  Type = "string" 
              }
          });
      } 
  }

