<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" indent="no" />
    <xsl:template match="/">
        \documentclass[10pt]{article}
        \usepackage{geometry}
        \geometry{a4paper,total={170mm,257mm},left=20mm,top=20mm,}
        \usepackage{longtable}
        \begin{document}
            \title{Flight Report}
            \author{XML Group 09}
            \date{\today}
            \maketitle
            \newpage
            \begin{longtable}{| p{2cm} | p{2cm} | p{2cm} | p{1.5cm} | p{4cm} | p{4cm} |}
            \hline
            Flight Id &amp; Country &amp; Position &amp; Status &amp; Departure Airport &amp; Arrival Airport \\
            \hline
            \hline
            \endhead
            \endfoot
            \endlastfoot

            <xsl:apply-templates select="/flights_data"/>
            \hline
            \end{longtable}
        \end{document}
    </xsl:template>

    <xsl:template match="/flights_data">
        <xsl:for-each select="./flight">
            <xsl:sort select="./@id" order="ascending"/>
            <xsl:value-of select="@id"/> &amp; <xsl:value-of select="./country"/> &amp;
            (<xsl:value-of select="./position/lat"/>, <xsl:value-of select="./position/lng"/>) &amp; <xsl:value-of select="./status"/>
            &amp; <xsl:value-of select="./departure_airport/name"/> &amp; <xsl:value-of select="./arrival_airport/name"/> \\
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>