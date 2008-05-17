<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version = '1.0'
    xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
    
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/collection">
    <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
        <head>
            <title>Fortunes</title>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        </head>
        <body>
            <xsl:apply-templates select="list/fortune" />
        </body>
    </html>
</xsl:template>

<xsl:template match="fortune">
    <div xmlns="http://www.w3.org/1999/xhtml" class="fortune">
        <h3 id="{@id}"><xsl:call-template name="get_header" /></h3>
        <xsl:choose>
            <xsl:when test="irc">
                <table class="irc-conversation">
                    <tbody>
                        <xsl:apply-templates select="irc/body"/>
                    </tbody>
                </table>
            </xsl:when>
            <xsl:when test="raw">
                <xsl:apply-templates select="raw" />
            </xsl:when>
            <xsl:when test="quote">
                <xsl:apply-templates select="quote" />
            </xsl:when>
        </xsl:choose> 
    </div>
</xsl:template>

<xsl:template match="body">
    <xsl:apply-templates select="saying|me_is|joins|leaves" />
</xsl:template>

<xsl:template match="saying|me_is|joins|leaves">
    <tr xmlns="http://www.w3.org/1999/xhtml">
        <xsl:attribute name="class">
            <xsl:value-of select="name(.)" />
        </xsl:attribute>
        <td class="who">
            <xsl:choose>
                <xsl:when test="name(.) = 'me_is'">
                    <xsl:text>* </xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'joins'">
                    <xsl:text>←</xsl:text>
                </xsl:when>
                <xsl:when test="name(.) = 'leaves'">
                    <xsl:text>→</xsl:text>
                </xsl:when>
            </xsl:choose> 
            <xsl:value-of select="@who" />
        </td>        
        <td class="text">
            <xsl:value-of select="." />
        </td>
    </tr>
</xsl:template>

<xsl:template name="get_irc_default_header">
    <xsl:choose>
        <xsl:when test="info">
            <xsl:if test="info/tagline">
                <xsl:value-of select="info/tagline" /> on
            </xsl:if>
            <xsl:if test="info/network">
                <xsl:value-of select="info/network" />'s
            </xsl:if>
            <xsl:value-of select="info/channel" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>Unknown Subject</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="get_header">
    <xsl:choose>
        <xsl:when test="meta/title">
            <xsl:value-of select="meta/title" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:call-template name="get_irc_default_header" select="irc" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template match="raw">
    <pre xmlns="http://www.w3.org/1999/xhtml" class="raw">
        <xsl:value-of select="body/text"/>
    </pre>
    <xsl:if test="info/*">
        <table xmlns="http://www.w3.org/1999/xhtml" class="info">
            <tbody>
                <xsl:apply-templates select="info/*" name="raw_info_subs"/>
            </tbody>
        </table>
    </xsl:if>
</xsl:template>

<xsl:template match="quote">
    <blockquote>
        <xsl:apply-templates select="body/p"/>
    </blockquote>
    <xsl:if test="info/*">
        <table xmlns="http://www.w3.org/1999/xhtml" class="info">
            <tbody>
                <xsl:apply-templates select="info/*" name="raw_info_subs"/>
            </tbody>
        </table>
    </xsl:if>
</xsl:template>

<xsl:template match="*" name="raw_info_subs">
    <tr xmlns="http://www.w3.org/1999/xhtml" class="{name(.)}">
        <td class="field">
            <b>
                <xsl:choose>
                    <xsl:when test="name(.) = 'author'">
                        <xsl:text>Author</xsl:text>
                    </xsl:when>
                    <xsl:when test="name(.) = 'work'">
                        <xsl:text>Work</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="name(.)" />
                    </xsl:otherwise>
                </xsl:choose> 
            </b>
        </td>
        <td class="value">
            <xsl:choose>
                <xsl:when test="@href">
                    <a href="{@href}">
                        <xsl:value-of select="." />
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="." />
                </xsl:otherwise>
            </xsl:choose>
        </td>
    </tr>
</xsl:template>
</xsl:stylesheet>
