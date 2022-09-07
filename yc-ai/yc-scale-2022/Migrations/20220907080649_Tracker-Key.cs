using Microsoft.EntityFrameworkCore.Migrations;

namespace yc_scale_2022.Migrations
{
    public partial class TrackerKey : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TrackerKey",
                table: "asr_recognition",
                nullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TrackerKey",
                table: "asr_recognition");
        }
    }
}
