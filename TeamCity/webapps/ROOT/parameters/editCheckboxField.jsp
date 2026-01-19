<%@include file="/include-internal.jsp"%>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props"  %>
<jsp:useBean id="context" scope="request" type="jetbrains.buildServer.controllers.parameters.ParameterEditContext"/>
<jsp:useBean id="checkedValue" scope="request" type="java.lang.String"/>

<tr>
  <th><label for="checkedValue">Checked value:<bs:help file="CheckboxParameter"/></label></th>
  <td>
    <props:textProperty name="checkedValue" className="longField" value="${checkedValue}"/>
  </td>
</tr>

<tr>
  <th><label for="uncheckedValue">Unchecked value:</label></th>
  <td>
    <props:textProperty name="uncheckedValue" className="longField"/>
  </td>
</tr>