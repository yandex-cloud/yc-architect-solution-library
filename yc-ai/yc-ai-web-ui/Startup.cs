using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using NSwag;
using Microsoft.AspNetCore.ResponseCompression;
using yc.ai.webUI.Hub;

namespace yc.ai.webUI
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {

            // services.AddControllers().AddNewtonsoftJson(); 
            services.AddControllers();
            services.AddRazorPages();           
            services.AddSignalR();
            services.AddCors();
            services.AddOpenApiDocument();
            services.AddResponseCompression(opts =>
            {
                opts.MimeTypes = ResponseCompressionDefaults.MimeTypes.Concat(
                    new[] { "application/octet-stream" });
            });
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                app.UseExceptionHandler("/Error");
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseResponseCompression();
            app.UseHttpsRedirection();
            app.UseStaticFiles();
            
            app.UseRouting();

            app.UseAuthorization();
            app.UseCors(options => options.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());

            app.UseOpenApi(settings =>
            {
                settings.PostProcess = (document, request) =>
                {
                    document.Info.Version = "v1";
                    document.Info.Title = "SpeechKit demo UI API";
                    document.Info.Contact = new OpenApiContact { Name = "Maxim Khlupnov", Email = "m.khlupnov@yandex.ru" };
                    

                    document.Info.License = new OpenApiLicense
                    {
                        Name = "Use under MIT License",
                        Url = "https://github.com/yandex-cloud/yc-architect-solution-library/tree/ai/yc-ai"
                    };
                };
            });

            app.UseSwaggerUi3();
            

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllerRoute(
                     name: "default",
                     pattern: "{controller=Home}/{action=Stt}/{id?}");
                endpoints.MapRazorPages();
                endpoints.MapControllers();
                endpoints.MapHub<SpeechKitHub>("/asrhub");
            });
            /* app.UseEndpoints(endpoints =>
             {
                 
             });*/
        }
    }
}
