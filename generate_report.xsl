<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" omit-xml-declaration="yes" indent="no" />
    <xsl:param name="qty" select="qty"/>
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
            <xsl:choose>
            <xsl:when test="/flights_data/error"><xsl:value-of select="/flights_data/error"/></xsl:when>
            <xsl:otherwise>
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
            </xsl:otherwise>
            </xsl:choose>
        \end{document}
    </xsl:template>

    <xsl:template name="table-column-field">
        <xsl:param name="query"/>
        <xsl:choose>
            <xsl:when test="not($query) or $query = ''">\textit{No information}</xsl:when>
            <xsl:otherwise><xsl:value-of select="$query"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="/flights_data">
        <xsl:for-each select="./flight">
            <xsl:sort select="./@id" order="ascending"/>
            <xsl:if test="not(position() > $qty)">    
                <xsl:value-of select="@id"/> &amp; 
                <xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./country"/>
                </xsl:call-template> &amp;
                (<xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./position/lat"/>
                </xsl:call-template>,
                <xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./position/lng"/>
                </xsl:call-template>) &amp;
                <xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./status"/>
                </xsl:call-template> &amp;
                <xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./departure_airport/name"/>
                </xsl:call-template> &amp;
                <xsl:call-template name="table-column-field">
                <xsl:with-param name="query" select="./arrival_airport/name"/>
                </xsl:call-template> \\
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
