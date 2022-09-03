using Microsoft.EntityFrameworkCore.Migrations;

namespace yc_scale_2022.Migrations
{
    public partial class Fixtypo : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_asr_aternative_asr_recognition_AlternativeId",
                table: "asr_aternative");

            migrationBuilder.DropForeignKey(
                name: "FK_asr_word_asr_aternative_AlternativeId",
                table: "asr_word");

            migrationBuilder.DropPrimaryKey(
                name: "PK_asr_aternative",
                table: "asr_aternative");

            migrationBuilder.RenameTable(
                name: "asr_aternative",
                newName: "asr_alternative");

            migrationBuilder.AddColumn<double>(
                name: "AudioLen",
                table: "asr_recognition",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_asr_alternative",
                table: "asr_alternative",
                column: "AlternativeId");

            migrationBuilder.AddForeignKey(
                name: "FK_asr_alternative_asr_recognition_AlternativeId",
                table: "asr_alternative",
                column: "AlternativeId",
                principalTable: "asr_recognition",
                principalColumn: "RecognitionId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_asr_word_asr_alternative_AlternativeId",
                table: "asr_word",
                column: "AlternativeId",
                principalTable: "asr_alternative",
                principalColumn: "AlternativeId",
                onDelete: ReferentialAction.Cascade);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_asr_alternative_asr_recognition_AlternativeId",
                table: "asr_alternative");

            migrationBuilder.DropForeignKey(
                name: "FK_asr_word_asr_alternative_AlternativeId",
                table: "asr_word");

            migrationBuilder.DropPrimaryKey(
                name: "PK_asr_alternative",
                table: "asr_alternative");

            migrationBuilder.DropColumn(
                name: "AudioLen",
                table: "asr_recognition");

            migrationBuilder.RenameTable(
                name: "asr_alternative",
                newName: "asr_aternative");

            migrationBuilder.AddPrimaryKey(
                name: "PK_asr_aternative",
                table: "asr_aternative",
                column: "AlternativeId");

            migrationBuilder.AddForeignKey(
                name: "FK_asr_aternative_asr_recognition_AlternativeId",
                table: "asr_aternative",
                column: "AlternativeId",
                principalTable: "asr_recognition",
                principalColumn: "RecognitionId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_asr_word_asr_aternative_AlternativeId",
                table: "asr_word",
                column: "AlternativeId",
                principalTable: "asr_aternative",
                principalColumn: "AlternativeId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
