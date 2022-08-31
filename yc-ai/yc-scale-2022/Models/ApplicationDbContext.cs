namespace yc_scale_2022.Models
{
    using Microsoft.EntityFrameworkCore;
    using Microsoft.Extensions.Configuration;


    public class ApplicationDbContext : DbContext
    {
        protected readonly IConfiguration Configuration;

        public ApplicationDbContext(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder options)
        {
            // connect to postgres with connection string from app settings
            options.UseNpgsql(Configuration.GetConnectionString("SentimentsDatabase"));
        }

        public DbSet<AsrSession> AsrSessions { get; set; }
        public DbSet<SpeechKitResponseModel> AsrResponse { get; set; }
        public DbSet<EmotionsList> EmotionsLists { get; set; }
    }
}

