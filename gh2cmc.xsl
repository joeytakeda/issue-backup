<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:array="http://www.w3.org/2005/xpath-functions/array"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:jt="foo"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="#all"
	expand-text="yes"
	version="3.0">
	
	<xsl:output method="xml" indent="yes"/>
	<xsl:mode on-no-match="shallow-skip"/>
	<xsl:mode name="html" on-no-match="shallow-skip"/>
	<xsl:param name="dir" select="'./issues'"/>
	<xsl:param name="out" select="'./tei'"/>
	<xsl:param name="files" select="''"/>
	
	<xsl:variable name="dir.resolved" select="resolve-uri($dir)"/>
	<xsl:variable name="out.resolved" select="resolve-uri($out)"/>
	

	<xsl:variable name="files.resolved" as="xs:anyURI+">
		<xsl:choose>
			<xsl:when test="$files = ''">
				<xsl:sequence select="uri-collection($dir || '?select=*.json;recurse=yes')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="$files">
					<xsl:sequence select="tokenize(.,'\s*,\s*') ! resolve-uri(.)"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:template name="go">
		<xsl:message select="$dir.resolved"/>
		<xsl:message select="count($files.resolved)"/>
		<xsl:for-each select="$files.resolved">
			<xsl:call-template name="makeTEI"/>
		</xsl:for-each>
	</xsl:template>
	

	<xsl:template name="makeTEI">
		<xsl:variable name="basename" 
			select="substring-after(., $dir.resolved) => replace('\.json$', '')"/>
			<xsl:message select="$basename"/>
		<xsl:variable name="doc" select="json-doc(.)"/>
		<xsl:result-document href="{resolve-uri($out.resolved || '/' || $basename || '.xml')}" normalization-form="NFKD">
<!-- 			<xsl:message select="current-output-uri()"/> -->
			<xsl:processing-instruction name="xml-model">href="https://jenkins.tei-c.org/job/TEIP5-CMC-features/lastSuccessfulBuild/artifact/P5/release/xml/tei/custom/schema/relaxng/tei_all.rng" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
			<TEI xmlns="http://www.tei-c.org/ns/1.0">
				<teiHeader>
					<fileDesc>
						<titleStmt>
							<title>GitHub Issues</title>
						</titleStmt>
						<publicationStmt>
							<p/>
						</publicationStmt>
						<sourceDesc>
							<p>GitHub</p>
						</sourceDesc>
					</fileDesc>
					<profileDesc>
						<particDesc>
							<listPerson>
								<xsl:call-template name="participants">
									<xsl:with-param name="issues" select="$doc"/>
								</xsl:call-template>
							</listPerson>
						</particDesc>
					</profileDesc>
				</teiHeader>
				<text>
					<body>
					<xsl:for-each select="array:flatten($doc)">
							<xsl:call-template name="issue"/>
						</xsl:for-each>
					</body>
				</text>
				
			</TEI>
		</xsl:result-document>
		
		
	</xsl:template>
	
	<xsl:template name="participants">
		<xsl:param name="issues"/>
		<xsl:iterate select="array:flatten($issues)">
			<xsl:param name="people" select="map{}" as="map(*)"/>
			<xsl:on-completion>
				<xsl:for-each select="map:keys($people)">
					<xsl:sequence select="$people(.)"/>
					
				</xsl:for-each>
			</xsl:on-completion>
			<xsl:variable name="user" select=".?user" as="map(*)"/>
			<xsl:variable name="assignees" select="array:flatten(.?assignees)" as="map(*)*"/>
			<xsl:variable name="posters" select="array:flatten(.?comments) ! .?user"
				as="map(*)*"/>
			<xsl:variable name="newPeople" as="map(*)*">
				<xsl:for-each-group select="($user, $assignees, $posters)" group-by="jt:getUserID(.)">
					<xsl:if test="not(map:contains($people, current-grouping-key()))">
						<xsl:sequence select="current-group()[1]"/>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:next-iteration>
				<xsl:with-param name="people" select="if (empty($newPeople)) then $people else
					fold-right($newPeople, $people, function($person, $array){map:put($array, jt:getUserID($person), jt:userToPerson($person))})"/>
			</xsl:next-iteration>
		</xsl:iterate>
	</xsl:template>
	
	<xsl:template name="issue">
		<xsl:variable name="number" select="xs:integer(.?number)"/>
		<div type="issue" subtype="{.?state}" n="{$number}">
			<!--Not sure how best to model "assignees"-->
			<head><xsl:value-of select=".?title"/></head>
			<xsl:call-template name="post">
				<xsl:with-param name="issue_number" select="$number"/>
			</xsl:call-template>
			<div type="comments">
				<xsl:for-each select="array:flatten(.?comments)">
					<xsl:call-template name="post">
						<xsl:with-param name="position" select="position()" as="xs:integer"/>
						<xsl:with-param name="issue_number" select="$number"/>
					</xsl:call-template>
				</xsl:for-each>
			</div>
		</div>
	</xsl:template>
	
	<xsl:template name="post">
		<xsl:param name="issue_number"/>
		<xsl:param name="position" select="()"/>
		<post xml:id="{string-join(('issue', $issue_number, $position),'_')}" ref="{.?html_url}"
			when-iso="{.?created_at}" who="#{jt:getUserID(.?user)}">
	<!-- 		<ab>
				<code lang="gfm">
					<xsl:value-of select="replace(.?body, '&#xD;','')"/>
				</code>
			</ab> -->
			<xsl:apply-templates select="parse-xml-fragment(.?body_gfm)" mode="html"/>
			<xsl:call-template name="reactions"/>
		</post>
	</xsl:template>
	
	<xsl:template name="reactions">
		<xsl:variable name="reactions" select=".?reactions" as="map(*)"/>
		<xsl:where-populated>
			<trailer>
				<xsl:where-populated>
					<measureGrp>
						<xsl:sequence>
							<xsl:on-non-empty>
								<xsl:attribute name="type">reactions</xsl:attribute>
								<xsl:attribute name="corresp" select="$reactions?url"/>
							</xsl:on-non-empty>
							<xsl:for-each select="map:keys($reactions)[not(. = ('url','total_count'))]">
								<xsl:if test="$reactions(.) gt 0">
									<measure commodity="{.}" quantity="{$reactions(.)}"/>
								</xsl:if>
							</xsl:for-each>
						</xsl:sequence>
					</measureGrp>
				</xsl:where-populated>
				
			</trailer>
		</xsl:where-populated>
	</xsl:template>
	
	
	<xsl:template match="*:p" mode="html">
		<p>
			<xsl:apply-templates mode="#current"/>
		</p>
	</xsl:template>
	
	<xsl:template match="*:div" mode="html">
		<ab>
			<xsl:apply-templates mode="#current"/>
		</ab>
	</xsl:template>
	
	<xsl:template match="*:div[contains-token(@class,'highlight')]" mode="html">
		<xsl:choose>
			<xsl:when test="contains-token(@class,'highlight-source-xml')">
				<xsl:variable name="text" select="string-join(descendant::text(),'')" as="xs:string"/>

					<xsl:try>
						<egXML xmlns="http://www.tei-c.org/ns/Examples">
						
							<xsl:apply-templates select="parse-xml-fragment($text)" mode="eg"/>
						</egXML>
						<xsl:catch>
							<xsl:sequence select="$text"/>
						</xsl:catch>
					</xsl:try>
			</xsl:when>
			<xsl:otherwise>
				<ab>
					<xsl:apply-templates mode="#current"/>
				</ab>
			</xsl:otherwise>			
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="*" mode="eg">
		<xsl:element name="{local-name()}" namespace="http://www.tei-c.org/ns/Examples">
			<xsl:apply-templates select="node()" mode="#current"/>
		</xsl:element>	
	</xsl:template>
	
	<xsl:template match="*:pre" mode="html">
		<eg>
			<xsl:choose>
				<xsl:when test="parent::*:div and not(*:code)">
					<xsl:call-template name="code"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates mode="#current"/>
				</xsl:otherwise>
			</xsl:choose>

		</eg>
	</xsl:template>

	
	<xsl:template match="*:code" name="code" mode="html">
		<code>
			<xsl:if test="ancestor::*:div[matches(@class,'highlight-source-')]">
				<xsl:attribute name="lang" select="tokenize(*:div[matches(@class,'highlight-source-')][1]/@class)[matches(.,'highlight-source-')] => replace('highlight-source-','')"/>
			</xsl:if>
			<xsl:apply-templates mode="#current"/>
		</code>
	</xsl:template>
	
	<xsl:template match="text()" mode="html">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="*:ul | *:ol" mode="html">
		<list>
			<xsl:apply-templates mode="#current"/>
		</list>
	</xsl:template>
	
	<xsl:template match="*:li" mode="html">
		<item>
			<xsl:apply-templates mode="#current"/>
		</item>
	</xsl:template>
	
	<xsl:template match="*:blockquote[descendant::*:a[matches(@href,'https://github.com/notifications/unsubscribe-auth/')]]" mode="html"/>
	
	<xsl:template match="*:blockquote" mode="html">
		<quote>
			<xsl:apply-templates mode="#current"/>
		</quote>
	</xsl:template>

	<xsl:template match="*:table" mode="html">
		<table>
			<xsl:apply-templates mode="#current"/>
		</table>
	</xsl:template>


	<xsl:template match="*:tr" mode="html">
		<row>
			<xsl:if test="parent::*:thead">
				<xsl:attribute name="role">label</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates mode="#current"/>
		</row>
	</xsl:template>

	<xsl:template match="*:td | *:th" mode="html">
		<cell>
		
			<xsl:apply-templates mode="#current"/>
		</cell>
	</xsl:template>
	
	<xsl:template match="*:a[@href]" mode="html">
		<ref target="{@href}">
			<xsl:apply-templates mode="#current"/>
		</ref>
	</xsl:template>
	
	
	<xsl:function name="jt:userToPerson" as="element(person)">
		<xsl:param name="object" as="map(*)"/>
		<person xml:id="{jt:getUserID($object)}" n="{$object?id}" >
			<persName>
				<addName><xsl:value-of select="$object?login"/></addName>
			</persName>
			<ptr target="{$object?html_url}"/>
		</person>
	</xsl:function>
	
	<xsl:function name="jt:getUserID" as="xs:string?">
		<xsl:param name="object" as="map(*)?"/>
		<xsl:if test="exists($object)">
			<xsl:sequence select="string($object?login)"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:function name="jt:isUser" as="xs:boolean">
		<xsl:param name="object" as="map(*)"/>
		<xsl:sequence select="map:contains($object, 'login') and $object?type = 'User'"/>
	</xsl:function>
	
	
</xsl:stylesheet>