using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Security.Policy;

namespace yc_scale_2022.Models
{

    [Table("dic_substitution")]
   
    public class SubstDictionary
    {
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Key]
        public int substitutionRuleId { get; set; }

        public string  patternMatch { get; set; }
        
        public string replacement { get; set; }

    }
}
